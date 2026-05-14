import os
import sys
import requests

COUNTRY_NAME  = os.getenv("COUNTRY_NAME", "Chile")
RESTCOUNTRIES = "https://restcountries.com/v3.1/name"
OPEN_METEO    = "https://api.open-meteo.com/v1/forecast"
TIMEOUT       = int(os.getenv("REQUEST_TIMEOUT", "10"))


def configure_stdio_utf8():
    """Evita UnicodeEncodeError en Windows (cp1252) al imprimir emojis y símbolos."""
    if sys.platform == "win32":
        try:
            import ctypes

            ctypes.windll.kernel32.SetConsoleOutputCP(65001)
            ctypes.windll.kernel32.SetConsoleCP(65001)
        except Exception:
            pass
    for stream in (sys.stdout, sys.stderr):
        reconf = getattr(stream, "reconfigure", None)
        if callable(reconf):
            try:
                reconf(encoding="utf-8", errors="replace")
            except Exception:
                pass


def fetch_country(name):
    url = f"{RESTCOUNTRIES}/{requests.utils.quote(name)}"
    try:
        resp = requests.get(url, timeout=TIMEOUT)
        resp.raise_for_status()
        data = resp.json()
        if not data:
            raise ValueError(f"No se encontraron resultados para '{name}'.")
        return data[0]
    except requests.exceptions.ConnectionError:
        print("[ERROR] Sin conexión a internet o el servidor no responde.")
        sys.exit(1)
    except requests.exceptions.Timeout:
        print(f"[ERROR] Tiempo de espera agotado ({TIMEOUT}s).")
        sys.exit(1)
    except requests.exceptions.HTTPError as e:
        code = e.response.status_code
        if code == 404:
            print(f"[ERROR 404] País '{name}' no encontrado.")
        elif code == 401:
            print("[ERROR 401] Credenciales inválidas.")
        elif code == 429:
            print("[ERROR 429] Demasiadas solicitudes. Intente más tarde.")
        else:
            print(f"[ERROR {code}] Respuesta inesperada: {e}")
        sys.exit(1)
    except (ValueError, KeyError) as e:
        print(f"[ERROR] Problema al interpretar los datos: {e}")
        sys.exit(1)

def fetch_weather(lat, lon):
    params = {
        "latitude":  lat,
        "longitude": lon,
        "current":   "temperature_2m,weathercode",
        "timezone":  "auto",
    }
    try:
        resp = requests.get(OPEN_METEO, params=params, timeout=TIMEOUT)
        resp.raise_for_status()
        return resp.json().get("current", {})
    except requests.exceptions.ConnectionError:
        print("[WARN] Sin conexión para obtener clima. Continuando sin datos climáticos.")
        return {}
    except requests.exceptions.Timeout:
        print("[WARN] Tiempo de espera agotado para Open-Meteo.")
        return {}
    except requests.exceptions.HTTPError as e:
        print(f"[WARN] Error HTTP {e.response.status_code} en Open-Meteo.")
        return {}
    except (ValueError, KeyError):
        return {}

def weather_description(code):
    table = {
        0:  "Cielo despejado ",
        1:  "Mayormente despejado ",
        2:  "Parcialmente nublado ",
        3:  "Nublado ",
        45: "Niebla ",
        51: "Llovizna ligera ",
        61: "Lluvia ligera ",
        71: "Nieve ligera ",
        80: "Chubascos ",
        95: "Tormenta eléctrica ",
    }
    for threshold in sorted(table.keys(), reverse=True):
        if code >= threshold:
            return table[threshold]
    return "Condición desconocida"

def main():
    sep = "═" * 58
    print(sep)
    print(f"    WORLD EXPLORER — País consultado: {COUNTRY_NAME}")
    print(sep)

    country = fetch_country(COUNTRY_NAME)

    # Variable 1: nombre oficial del país
    nombre_pais = country.get("name", {}).get("official", "N/D")

    # Variable 2: capital
    capital = ", ".join(country.get("capital", ["N/D"]))

    # Variable 3: moneda (nombre, código y símbolo)
    currencies_raw = country.get("currencies", {})
    if currencies_raw:
        code_moneda, info_moneda = next(iter(currencies_raw.items()))
        moneda = f"{info_moneda.get('name', 'N/D')} ({code_moneda}) {info_moneda.get('symbol', '')}".strip()
    else:
        moneda = "N/D"

    # Variable 4: idioma oficial
    idioma = ", ".join(country.get("languages", {}).values()) or "N/D"

    # Variables 5 y 6: temperatura y condición climática
    latlng = country.get("latlng", [None, None])
    lat, lon = latlng[0], latlng[1]
    temperatura = "N/D"
    condicion   = "N/D"
    if lat is not None and lon is not None:
        weather = fetch_weather(lat, lon)
        if weather:
            temperatura = f"{weather.get('temperature_2m', 'N/D')} °C"
            wcode       = weather.get("weathercode", -1)
            condicion   = weather_description(wcode) if isinstance(wcode, int) else "N/D"

    print(f"\n    DATOS DEL PAÍS")
    print(f"  {'nombre_pais':<20}: {nombre_pais}")
    print(f"  {'capital':<20}: {capital}")
    print(f"  {'moneda':<20}: {moneda}")
    print(f"  {'idioma':<20}: {idioma}")
    print(f"\n    CLIMA ACTUAL")
    print(f"  {'temperatura':<20}: {temperatura}")
    print(f"  {'condicion':<20}: {condicion}")
    print(f"\n{sep}")
    print("    Consulta completada exitosamente.")
    print(sep)

if __name__ == "__main__":
    configure_stdio_utf8()
    main()
