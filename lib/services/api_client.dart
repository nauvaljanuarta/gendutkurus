import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  static SupabaseClient get client => Supabase.instance.client;
}
