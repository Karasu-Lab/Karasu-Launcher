import 'package:karasu_launcher/utils/minecraft/mod/action_result.dart';

abstract interface class IModLoaderInstaller {
  Future<ActionResult> install();
}