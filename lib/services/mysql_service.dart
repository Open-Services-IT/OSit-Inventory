import 'dart:developer';

import 'package:mysql_client/mysql_client.dart';
import 'package:tuple/tuple.dart';

import 'app_storage.dart';

class Mysql {
  final store = AppStorage();

  Future<MySQLConnection> getConnection() async {
    final conn = await MySQLConnection.createConnection(
        host: store.host,
        port: store.port,
        userName: store.user,
        password: store.password,
        databaseName: store.database,
        secure: false);
    await conn.connect();
    return conn;
  }

  Future<Map<String, Tuple2<String, String>>> readQRData(String qrCode) async {
    Map<String, Tuple2<String, String>> map = {};
    var SQLinvent = """
SELECT 'INFO' AS Tipo, '<<' AS Valor
UNION SELECT 'Nombre' AS Tipo, hardware.name AS Valor FROM hardware WHERE NAME=:qrcode
UNION SELECT 'Dirección IP' AS Tipo, hardware.ipsrc AS Valor FROM hardware WHERE NAME=:qrcode
UNION SELECT 'Sistema Operativo' AS Tipo, hardware.osname AS Valor FROM hardware WHERE NAME=:qrcode
UNION SELECT 'Compilación' AS Tipo, hardware.osversion AS Valor FROM hardware WHERE NAME=:qrcode
UNION SELECT 'Usuario conectado' AS Tipo, hardware.userid AS Valor FROM hardware WHERE NAME=:qrcode
UNION SELECT 'Clave de Windows' AS Tipo, hardware.winprodkey AS Valor FROM hardware WHERE NAME=:qrcode
UNION SELECT 'Versión del agente' AS Tipo, hardware.useragent AS Valor FROM hardware WHERE NAME=:qrcode
UNION SELECT 'Ultimo inventario' AS Tipo, hardware.lastdate AS Valor FROM hardware WHERE NAME=:qrcode
UNION SELECT 'Ultimo contacto' AS Tipo, hardware.lastcome AS Valor FROM hardware WHERE NAME=:qrcode

UNION SELECT 'FABRICANTE' AS Tipo, '<<' AS Valor
UNION SELECT 'Fabricante' AS Tipo, b.smanufacturer AS Valor FROM hardware h INNER JOIN bios b ON h.id = b.hardware_id WHERE h.name = :qrcode
UNION SELECT 'Modelo' AS Tipo, b.smodel AS Valor FROM hardware h INNER JOIN bios b ON h.id = b.hardware_id WHERE h.name = :qrcode
UNION SELECT 'Nº de serie' AS Tipo, b.ssn  AS Valor FROM hardware h INNER JOIN bios b ON h.id = b.hardware_id WHERE h.name = :qrcode
UNION SELECT 'BIOS - Versión' AS Tipo, b.bversion  AS Valor FROM hardware h INNER JOIN bios b ON h.id = b.hardware_id WHERE h.name = :qrcode
UNION SELECT 'BIOS - Fecha' AS Tipo, b.bdate  AS Valor FROM hardware h INNER JOIN bios b ON h.id = b.hardware_id WHERE h.name = :qrcode

UNION SELECT 'PROCESADOR' AS Tipo, '<<' AS Valor
UNION SELECT 'Procesador' AS Tipo, hardware.processort AS Valor FROM hardware WHERE NAME=:qrcode
UNION SELECT 'Procesadores' AS Tipo, hardware.processorn AS Valor FROM hardware WHERE NAME=:qrcode
UNION SELECT 'Cores' AS Tipo, c.cores FROM hardware h INNER JOIN cpus c ON h.id = c.hardware_id WHERE h.name = :qrcode

UNION SELECT 'MEMORIA' AS Tipo, '<<' AS Valor
UNION SELECT 'Memoria total' AS Tipo, CONCAT(ROUND(hardware.memory/1024,0), " GB") AS Valor FROM hardware WHERE NAME=:qrcode
UNION SELECT 'Slots ocupados' AS Tipo, COUNT(*) FROM hardware h INNER JOIN memories m ON h.id = m.hardware_id WHERE h.name = :qrcode AND m.type != 'Empty slot'
UNION SELECT 'Slots libres' AS Tipo, COUNT(*) FROM hardware h INNER JOIN memories m ON h.id = m.hardware_id WHERE h.name = :qrcode AND m.type = 'Empty slot'

UNION SELECT 'ALMACENAMIENTO' AS Tipo, '<<' AS Valor
UNION SELECT
  CONCAT('Disco: ', s.name) AS Tipo,
  CONCAT('Capacidad: ',CONCAT(ROUND(s.disksize / 1024, 0), " GB"), ' - Versión de firmware: ', s.firmware) AS Valor
FROM hardware h
INNER JOIN storages s ON h.id = s.hardware_id
WHERE h.name = :qrcode 
AND (s.description = 'Disk drive' OR s.description = 'Unidad de disco')

UNION SELECT 'UNIDADES' AS Tipo, '<<' AS Valor
UNION SELECT
  d.letter AS Tipo,
  CONCAT('Sistema de archivos: ', d.filesystem, ' - Libre: ', CONCAT(ROUND(d.free / 1024, 0), " GB"), ' - Ocupado: ', CONCAT(ROUND(d.total / 1024, 0), " GB")) AS Valor
FROM hardware h
INNER JOIN drives d ON h.id = d.hardware_id
WHERE h.name = :qrcode 
AND d.type = 'Hard Drive'

UNION SELECT 'CONTROLADORAS' AS Tipo, '<<' AS Valor
UNION SELECT
  c.name  AS Tipo,
  c.type AS Valor
FROM hardware h
INNER JOIN controllers c ON h.id = c.hardware_id
WHERE h.name = :qrcode

UNION SELECT 'ADAPTADORES DE RED' AS Tipo, '<<' AS Valor
UNION SELECT
  c.description AS Tipo,
  CONCAT('MAC: ', c.macaddr, ' - Dirección IP: ', c.ipaddress, '/', c.ipmask, ' - Gateway: ', c.ipgateway, ' - Servidor DHCP: ', c.ipdhcp) AS Valor
FROM hardware h
INNER JOIN networks c ON h.id = c.hardware_id
WHERE h.name = :qrcode AND c.status = 'Up'

UNION SELECT 'TARJETA GRAFICA' AS Tipo, '<<' AS Valor
UNION SELECT 'Modelo' AS Tipo, v.name AS Valor FROM hardware h INNER JOIN videos v ON h.id = v.hardware_id WHERE h.name = :qrcode
UNION SELECT 'Memoria' AS Tipo, v.memory AS Valor  FROM hardware h INNER JOIN videos v ON h.id = v.hardware_id WHERE h.name = :qrcode
UNION SELECT 'Resolución' AS Tipo, v.resolution AS Valor FROM hardware h INNER JOIN videos v ON h.id = v.hardware_id WHERE h.name = :qrcode

UNION SELECT 'TARJETA DE SONIDO' AS Tipo, '<<' AS Valor
UNION SELECT
  s.name  AS Tipo,
  s.manufacturer AS Valor
FROM hardware h
INNER JOIN sounds s ON h.id = s.hardware_id
WHERE h.name = :qrcode 

UNION SELECT 'MONITOR' AS Tipo, '<<' AS Valor
UNION SELECT
  monitors.manufacturer AS Tipo, 
  CONCAT('Modelo: ', monitors.caption, ' - Número de serie: ', monitors.serial, ' - Tipo: ' , monitors.type, ' - Descripción: ' , monitors.description) AS Valor
FROM
  hardware
  JOIN monitors ON hardware.id = monitors.hardware_id
WHERE
  hardware.name = :qrcode

UNION SELECT 'IMPRESORAS' AS Tipo, '<<' AS Valor
UNION SELECT
  c.name AS Tipo,
  CONCAT('Driver: ', c.driver, ' - Puerto: ', c.port, ' - Compartida: ', CASE WHEN c.shared = 0 THEN 'No' WHEN c.shared = 1 THEN 'Si' END, ' - Impresora de red: ', CASE WHEN c.network = 0 THEN 'No' WHEN c.network = 1 THEN 'Si' END) AS Valor
FROM hardware h
INNER JOIN printers c ON h.id = c.hardware_id
WHERE h.name = :qrcode

UNION SELECT 'SOFTWARE' AS Tipo, '<<' AS Valor
UNION SELECT
  sn.name AS Tipo,
  sv.version AS Valor
FROM
  hardware h
  JOIN software hs ON h.id = hs.hardware_id
  JOIN software s ON hs.id = s.id
  JOIN software_name sn ON s.name_id = sn.id
  JOIN software_version sv ON s.version_id = sv.id
WHERE
 h.name = :qrcode
;""";
    try {
      var conn = await getConnection();
      //centreon_storage.hosts.name
      log('${DateTime.now().toIso8601String()}_readQRData $qrCode');

      // 1 query
      var result = await conn.execute(SQLinvent, {"qrcode": qrCode});
      log('${DateTime.now().toIso8601String()} result.rows ${result.rows.length}');

      for (final row in result.rows) {
        print(row.colAt(0));
        // print(row.colByName("title"));

        // print all rows as Map<String, String>
        // print(row.assoc());
        // map['Dirección IP'] = Tuple2('${row.colAt(3)}', "0");
        if (row.colAt(1) == '<<') {
          String line = '${row.colAt(0)}';
          map[line] = Tuple2('', '0');
        } else {
          map['${row.colAt(0)}'] = Tuple2('${row.colAt(1)}', '0');
        }
      }

      conn.close();
    } catch (e) {
      map = {'ERROR': Tuple2(e.toString(), '2')}; //2 COlor ROJO
      log('${DateTime.now().toIso8601String()} ERROR $e');
    }

    return Future(() {
      return map;
    });
  }
}
