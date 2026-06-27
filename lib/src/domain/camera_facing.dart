/// Physical camera selection.
enum CameraFacing {
  back,
  front;

  static CameraFacing fromIndex(int i) =>
      i >= 0 && i < values.length ? values[i] : back;

  CameraFacing get opposite => this == back ? front : back;
}
