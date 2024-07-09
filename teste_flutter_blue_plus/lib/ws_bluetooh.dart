// A Word Synapse library to manage bluetooth
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  final String targetDeviceName;

  BluetoothManager(this.targetDeviceName);
  BluetoothDevice? blueDevice;
  BluetoothCharacteristic? readCharacteristic;
  BluetoothCharacteristic? writeCharacteristic;
  String currentReadData = "";
  String currentWriteData = "";
  bool _isBlueTurnedOn = false;
  bool _isBlueFound = false;
  bool _isBlueConnected = false;
  bool _isBlueWriteService = false;
  bool _isBlueReadService = false;

  Future<bool> isBluetoothAvailable() async {
    print("1 - Turn On Bluetooth");
    // first, check if bluetooth is supported by your hardware
    // Note: The platform is initialized on the first call to any FlutterBluePlus method.
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth Error 1");
      return false;
    }

    // handle bluetooth on & off
    // note: for iOS the initial state is typically BluetoothAdapterState.unknown
    // note: if you have permissions issues you will get stuck at BluetoothAdapterState.unauthorized
    var subscription1 =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      print(state);
      if (state == BluetoothAdapterState.on) {
        _isBlueTurnedOn = true;
      } else {
        _isBlueTurnedOn = false;
      }
    });

    // turn on bluetooth ourself if we can
    // for iOS, the user controls bluetooth enable/disable
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
      _isBlueTurnedOn = true;
    }

    // cancel to prevent duplicate listeners
    subscription1.cancel();

    // Wait for Bluetooth enabled & permission granted
    // In your real app you should use `FlutterBluePlus.adapterState.listen` to handle all states
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    return _isBlueTurnedOn;
  }

  Future<bool> scanDevices() async {
    if (_isBlueTurnedOn == true) {
      print("2 - Scan Device");
      // Start scanning for BLE devices
      FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        withNames: [targetDeviceName],
      ).catchError((error) {
        print("Error starting scan: $error");
      });

      // wait for scanning to stop
      await FlutterBluePlus.isScanning.where((val) => val == false).first;

      // listen to scan results
      // Note: `onScanResults` only returns live scan results, i.e. during scanning. Use
      //  `scanResults` if you want live scan results *or* the results from a previous scan.
      var subscription2 = FlutterBluePlus.scanResults.listen(
        (results) {
          if (results.isNotEmpty) {
            ScanResult r = results.last; // the most recently found device
            print(
                '${r.device.remoteId}: "${r.advertisementData.advName}" found!');
            blueDevice = r.device;
            _isBlueFound = true;
            //FlutterBluePlus.stopScan();
          } else {}
        },
        onError: (e) => print(e),
      );
    }
    return _isBlueFound;
  }

  Future<bool> connectDevice() async {
    if (_isBlueFound == true) {
      print("3 - Connect Device");
      if (blueDevice != null) {
        try {
          blueDevice!.connect();
          print('Conectado ao dispositivo ${blueDevice!.name}');
          _isBlueConnected = true;
        } catch (e) {
          print('Erro ao conectar: $e');
        }
      }
    }
    return _isBlueConnected;
  }

  Future<bool> findService() async {
    if (_isBlueConnected == true) {
      print("4 - Find Service");
      List<BluetoothService> services = await blueDevice!.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write) {
            writeCharacteristic = characteristic;
            _isBlueWriteService = true;
          }
          if (characteristic.properties.read) {
            readCharacteristic = characteristic;
            _isBlueReadService = true;
          }
        }
      }
    }
    return _isBlueReadService;
  }

  Future<void> write(String writeData) async {
    if (_isBlueWriteService == true) {
      print("6 - Write Device");
      currentWriteData = writeData;
      List<int> listWriteData = currentWriteData.codeUnits;
      writeCharacteristic!.write(listWriteData);
    }
  }

  Future<String> read() async {
    if (_isBlueReadService == true) {
      print("6 - Read Device");
      List<int>? value = await readCharacteristic?.read();
      currentReadData = String.fromCharCodes(value as Iterable<int>);
      if (currentReadData == currentWriteData) {
        currentReadData = "";
      }
      print(currentReadData);
    }
    return currentReadData;
  }
}
