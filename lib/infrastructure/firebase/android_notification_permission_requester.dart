typedef AndroidNotificationPermissionRequest = Future<bool?> Function();

class AndroidNotificationPermissionRequester {
  const AndroidNotificationPermissionRequester({
    required AndroidNotificationPermissionRequest requestPermission,
  }) : _requestPermission = requestPermission;

  final AndroidNotificationPermissionRequest _requestPermission;

  Future<bool?> request() {
    return _requestPermission();
  }
}
