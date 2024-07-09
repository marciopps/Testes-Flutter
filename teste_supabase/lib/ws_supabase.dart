// A Word Synapse library to manage supabase
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  // Cliente Supabase
  //final supabase = Supabase.instance.client;

  String actualTable = "";
  String dataRead = "";
  late List<Map<String, dynamic>> supabaseRead;

  Future<void> initialize(String supabaseUrl, String supabaseKey) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  void table(String inputTable) {
    actualTable = inputTable;
  }

  Future<void> writeNewData(String inputField, String inputValue) async {
    await Supabase.instance.client
        .from(actualTable)
        .insert({inputField: inputValue});
  }

  Future<void> readQuery(String inputField, int position) async {
    //final _dataStream =
    //   Supabase.instance.client.from(actualTable).toString();// .stream(primaryKey: ['id']);
    supabaseRead = await Supabase.instance.client
        .from(actualTable)
        .select(inputField)
        .order('id', ascending: true);
    //.eq('id', 1); // equals filter
    Map<String, dynamic> positionItem = supabaseRead[position];
    dataRead = positionItem[inputField].toString();
  }

  String readData() {
    return dataRead;
  }
}
