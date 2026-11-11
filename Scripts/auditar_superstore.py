#!/usr/bin/env python3
"""Audita un CSV de Sample Superstore sin cargarlo completo en memoria.

Uso:
  py -3 auditar_superstore.py "C:\\ruta\\Sample - Superstore.csv"
  py -3 auditar_superstore.py "C:\\ruta\\Sample - Superstore.csv" --delimiter "," --out "C:\\ruta\\auditoria_dataset.txt"
"""
import argparse
import csv
import json
import sys
from collections import Counter
from datetime import datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path

NULL_TOKENS = {"", "null", "none", "nan", "n/a", "na"}
DATE_FORMATS = ("%m/%d/%Y", "%m/%d/%y", "%Y-%m-%d", "%d/%m/%Y")


def clean_header(value):
    return (value or "").replace("\ufeff", "").strip()


def parse_date(value):
    value = (value or "").strip()
    if value.lower() in NULL_TOKENS:
        return None
    for fmt in DATE_FORMATS:
        try:
            return datetime.strptime(value, fmt).date()
        except ValueError:
            pass
    return None


def parse_decimal(value):
    value = (value or "").strip()
    if value.lower() in NULL_TOKENS:
        return None
    if value.endswith("%"):
        value = value[:-1].strip()
        try:
            return Decimal(value) / Decimal("100")
        except InvalidOperation:
            return None
    # En este dataset las comas dentro de textos vienen protegidas por comillas.
    # Para columnas numéricas, quitar separadores de miles es una normalización útil.
    value = value.replace(",", "")
    try:
        return Decimal(value)
    except InvalidOperation:
        return None


def guess_type(column):
    name = column.strip().lower()
    if name in {"order date", "ship date"}:
        return "DATE"
    if name in {"sales", "discount", "profit"}:
        return "DECIMAL"
    if name in {"row id", "quantity"}:
        return "INT"
    if name in {"postal code", "order id", "customer id", "product id"}:
        return "STRING"
    return "STRING"


def inspect_file(path, delimiter_arg=None):
    # utf-8-sig elimina BOM si existe; cp1252 cubre algunos CSV guardados desde Excel.
    encoding = "utf-8-sig"
    try:
        with path.open("r", encoding=encoding, newline="") as f:
            sample = f.read(65536)
    except UnicodeDecodeError:
        encoding = "cp1252"
        with path.open("r", encoding=encoding, newline="") as f:
            sample = f.read(65536)

    if delimiter_arg:
        delimiter = delimiter_arg
    else:
        try:
            delimiter = csv.Sniffer().sniff(sample, delimiters=",;\t|").delimiter
        except csv.Error:
            delimiter = ","

    report = {
        "archivo": str(path),
        "tamano_bytes": path.stat().st_size,
        "codificacion": encoding,
        "delimitador": "TAB" if delimiter == "\t" else delimiter,
        "campos": [],
        "tipos_hive_sugeridos": {},
        "filas_datos": 0,
        "filas_con_columnas_inconsistentes": 0,
        "nulos_por_campo": {},
        "row_id_duplicados_distintos": 0,
        "row_id_ocurrencias_duplicadas": 0,
        "ordenes_unicas": None,
        "clientes_unicos": None,
        "fechas_pedido_invalidas": 0,
        "fechas_envio_invalidas": 0,
        "envios_anteriores_al_pedido": 0,
        "ventas_menores_o_iguales_cero": 0,
        "descuentos_fuera_0_1": 0,
        "ejemplos": [],
        "observaciones": [],
    }

    row_id_counts = Counter()
    orders = set()
    customers = set()
    headers = None
    null_counts = Counter()
    seen_row_ids = set()
    duplicate_row_ids = set()

    try:
        with path.open("r", encoding=encoding, newline="") as f:
            reader = csv.DictReader(f, delimiter=delimiter)
            if not reader.fieldnames:
                raise ValueError("No se encontró una fila de encabezados.")
            headers = [clean_header(h) for h in reader.fieldnames]
            reader.fieldnames = headers
            report["campos"] = headers
            report["tipos_hive_sugeridos"] = {h: guess_type(h) for h in headers}
            expected_count = len(headers)

            for row in reader:
                if row is None:
                    continue
                report["filas_datos"] += 1
                # DictReader utiliza la clave None si sobran columnas.
                extra = row.get(None)
                missing = any(row.get(h) is None for h in headers)
                if extra is not None or missing:
                    report["filas_con_columnas_inconsistentes"] += 1

                normalized = {}
                for h in headers:
                    value = row.get(h)
                    value = value.strip() if isinstance(value, str) else ""
                    normalized[h.lower()] = value
                    if value.lower() in NULL_TOKENS:
                        null_counts[h] += 1

                if len(report["ejemplos"]) < 5:
                    report["ejemplos"].append({h: row.get(h) for h in headers})

                row_id = normalized.get("row id", "")
                if row_id and row_id.lower() not in NULL_TOKENS:
                    row_id_counts[row_id] += 1
                    if row_id in seen_row_ids:
                        duplicate_row_ids.add(row_id)
                    else:
                        seen_row_ids.add(row_id)

                order_id = normalized.get("order id", "")
                customer_id = normalized.get("customer id", "")
                if order_id and order_id.lower() not in NULL_TOKENS:
                    orders.add(order_id)
                if customer_id and customer_id.lower() not in NULL_TOKENS:
                    customers.add(customer_id)

                order_date = parse_date(normalized.get("order date", ""))
                ship_date = parse_date(normalized.get("ship date", ""))
                raw_order_date = normalized.get("order date", "")
                raw_ship_date = normalized.get("ship date", "")
                if raw_order_date and raw_order_date.lower() not in NULL_TOKENS and order_date is None:
                    report["fechas_pedido_invalidas"] += 1
                if raw_ship_date and raw_ship_date.lower() not in NULL_TOKENS and ship_date is None:
                    report["fechas_envio_invalidas"] += 1
                if order_date and ship_date and ship_date < order_date:
                    report["envios_anteriores_al_pedido"] += 1

                raw_sales = normalized.get("sales", "")
                sales = parse_decimal(raw_sales)
                if raw_sales and raw_sales.lower() not in NULL_TOKENS and sales is not None and sales <= 0:
                    report["ventas_menores_o_iguales_cero"] += 1

                raw_discount = normalized.get("discount", "")
                discount = parse_decimal(raw_discount)
                if raw_discount and raw_discount.lower() not in NULL_TOKENS and discount is not None and (discount < 0 or discount > 1):
                    report["descuentos_fuera_0_1"] += 1

    except csv.Error as exc:
        raise ValueError("Error leyendo el CSV: " + str(exc))

    report["nulos_por_campo"] = {h: null_counts.get(h, 0) for h in headers}
    report["row_id_duplicados_distintos"] = len(duplicate_row_ids)
    report["row_id_ocurrencias_duplicadas"] = sum(max(0, count - 1) for count in row_id_counts.values())
    report["ordenes_unicas"] = len(orders) if "order id" in [h.lower() for h in headers] else None
    report["clientes_unicos"] = len(customers) if "customer id" in [h.lower() for h in headers] else None

    if "postal code" in [h.lower() for h in headers]:
        report["observaciones"].append("Postal Code se recomienda como STRING para conservar ceros iniciales y evitar pérdida de formato.")
    if "order date" in [h.lower() for h in headers] or "ship date" in [h.lower() for h in headers]:
        report["observaciones"].append("Verifique el formato real de las fechas antes de convertirlas a DATE en Hive.")
    report["observaciones"].append("Los tipos Hive sugeridos son una propuesta inicial; confirme cada campo con los valores y formatos observados.")
    return report


def render_text(report):
    lines = [
        "AUDITORIA DEL DATASET SUPERSTORE",
        "=" * 38,
        "Archivo: " + report["archivo"],
        "Tamano: {:,} bytes".format(report["tamano_bytes"]),
        "Codificacion: " + report["codificacion"],
        "Delimitador: " + report["delimitador"],
        "",
        "ESTRUCTURA",
        "Campos detectados: {}".format(len(report["campos"])),
    ]
    for i, field in enumerate(report["campos"], 1):
        lines.append("{}. {} -> {}".format(i, field, report["tipos_hive_sugeridos"][field]))
    lines += [
        "",
        "CALIDAD Y VOLUMEN",
        "Filas de datos: {:,}".format(report["filas_datos"]),
        "Filas con cantidad de columnas inconsistente: {:,}".format(report["filas_con_columnas_inconsistentes"]),
        "Row ID duplicados distintos: {:,}".format(report["row_id_duplicados_distintos"]),
        "Ocurrencias duplicadas de Row ID (repeticiones despues de la primera): {:,}".format(report["row_id_ocurrencias_duplicadas"]),
        "Ordenes unicas: {}".format(report["ordenes_unicas"]),
        "Clientes unicos: {}".format(report["clientes_unicos"]),
        "Fechas de pedido invalidas: {:,}".format(report["fechas_pedido_invalidas"]),
        "Fechas de envio invalidas: {:,}".format(report["fechas_envio_invalidas"]),
        "Envios anteriores al pedido: {:,}".format(report["envios_anteriores_al_pedido"]),
        "Ventas menores o iguales a cero: {:,}".format(report["ventas_menores_o_iguales_cero"]),
        "Descuentos fuera de [0,1]: {:,}".format(report["descuentos_fuera_0_1"]),
        "",
        "NULOS POR CAMPO",
    ]
    for field, count in report["nulos_por_campo"].items():
        lines.append("{}: {:,}".format(field, count))
    lines += ["", "PRIMEROS 5 REGISTROS (muestra)"]
    for idx, item in enumerate(report["ejemplos"], 1):
        lines.append("Registro {}: {}".format(idx, json.dumps(item, ensure_ascii=False)))
    lines += ["", "OBSERVACIONES"]
    for note in report["observaciones"]:
        lines.append("- " + note)
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description="Audita estructura y calidad de un CSV de Superstore.")
    parser.add_argument("csv_path", help="Ruta del archivo CSV")
    parser.add_argument("--delimiter", help="Delimitador opcional: , ; TAB o |")
    parser.add_argument("--out", help="Ruta del informe TXT (opcional)")
    args = parser.parse_args()

    path = Path(args.csv_path)
    if not path.is_file():
        print("ERROR: no existe el archivo: {}".format(path), file=sys.stderr)
        return 2
    delimiter = "\t" if args.delimiter and args.delimiter.upper() == "TAB" else args.delimiter

    try:
        report = inspect_file(path, delimiter)
    except Exception as exc:
        print("ERROR: {}".format(exc), file=sys.stderr)
        return 1

    output = render_text(report)
    print(output)
    if args.out:
        out_path = Path(args.out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(output, encoding="utf-8")
        json_path = out_path.with_suffix(".json")
        json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print("Informe guardado en: {}".format(out_path))
        print("JSON guardado en: {}".format(json_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
