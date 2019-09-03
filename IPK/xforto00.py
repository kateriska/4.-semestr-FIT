#!/usr/bin/env python3.6

# Autor: Katerina Fortova (xforto00)
# Predmet: IPK
# Ukol: Projekt 1 - Klient pro OpenWeatherMap API
# Datum: unor - brezen 2019

import socket
import json
import sys


HOST = 'api.openweathermap.org'  # Host serveru
PORT = 80       # Port serveru

# Ulozeni argumentu:
api_key = sys.argv[1] # API klic
city = (sys.argv[2]).lower() # nazev mesta

url = f'http://{HOST}/data/2.5/weather?q={city}&appid={api_key}&units=metric'

request_format = f'GET {url} HTTP/1.1\r\nHost: {HOST}\r\nConnection: close\r\n\r\n' # format requestu pro server
request = request_format

request_to_bytes = request.encode()

try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
except socket.error as err:
    print ("Chyba - Socket se nepodarilo vytvorit!")

# vytvoreni socketu, pripojeni k serveru a sber dat:
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect((HOST, PORT))
    s.sendall(request_to_bytes)
    data = s.recv(1024) # obdrzena data

http_code = data.decode().split("\r\n")[0] # HTTP hlavicka s navratovym kodem
code = http_code[9:12] # navratovy kod serveru (dlouhy) - melo by byt 200 OK
code_long = http_code[9:] # navratovy kod serveru - triciselny

if (code == "401"):
    sys.stderr.write("Chyba - Vas API klic je neplatny!\n")
    exit(1)
elif (code == "404"):
    sys.stderr.write("Chyba - Vami zadane mesto nebylo nalezeno!\n")
    exit(1)
elif (code == "429"):
    sys.stderr.write("Chyba - Vas API klic je blokovan!\n")
    exit(1)
elif (code == "500"):
    sys.stderr.write("Chyba - Nastala interni chyba serveru!\n")
    exit(1)
elif (code_long != "200 OK"):
    sys.stderr.write("Neznama chyba!\n")
    exit(1)


data_cut = data.decode().split("\r\n\r\n")[1] # odstraneni HTTP informaci

if (data_cut.find("deg") == -1 ):
    sys.stderr.write("Chyba - Bezvetri nebo neznamy smer vetru! Zkuste to prosim pozdeji.\n")
    exit(1)

jdata = json.loads(data_cut) # nacteni informaci o pocasi do jsonu

# Prace s informacemi ze serveru:
# Nazev mesta:
print(jdata['name'])
# Popis pocasi:
print(jdata['weather'][0]['description'])
# Teplota:
temperature = str(jdata['main']['temp'])
print("temp:"+temperature+"°C")
# Vlhkost:
humidity = str(jdata['main']['humidity'])
print("humidity:"+humidity+"%")
# Tlak:
pressure = str(jdata['main']['pressure'])
print("pressure:"+pressure+"hPa")
# Rychlost vetru:
wind_kmh = str(round((jdata['wind']['speed']*3.6), 2))
print("wind-speed: "+wind_kmh+"km/h")
# Smer vetru:
wind_deg = str(jdata['wind']['deg'])
print("wind-deg: "+wind_deg)
