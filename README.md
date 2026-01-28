# LUTs Example

A Flutter example of using [LUTs](https://en.wikipedia.org/wiki/Lookup_table) 
for photo filters.  This was created as a demonstration of the new high bit 
depth texture support for fragment shaders in Flutter.

## Getting Started

This demo requires Flutter version >= 3.41 or the `main` channel.

```shell
# Regenerate the platform files
flutter create --no-overwrite .
fluter run
```

New APIs from Flutter 3.41 used:

- [decodeImageFromPixelsSync](https://github.com/flutter/flutter/blob/f3c54a697e45e9bcc9104912d4a7664982a2b4ee/engine/src/flutter/lib/ui/painting.dart#L2753) - A synchronous version of
`decodeImageFromPixels`.
- [PixelFormat.rgbaFloat32](https://github.com/flutter/flutter/blob/f3c54a697e45e9bcc9104912d4a7664982a2b4ee/engine/src/flutter/lib/ui/painting.dart#L1912) - A 32-bit float RGBA pixel
format.  This was previously available but now works with
`decodeImageFromPixelsSync`. [TargetPixelFormat.rgbaFloat32](https://github.com/flutter/flutter/blob/f3c54a697e45e9bcc9104912d4a7664982a2b4ee/engine/src/flutter/lib/ui/painting.dart#L1925)
is used in other API calls.

## Screenshot

![Screenshot](./images/luts.gif)

## Acknowledgements

- LUTs from [Pond5](https://blog.pond5.com/78810-35-free-luts-for-color-grading-videos/)
- Image supplied from [Nano Banana](https://gemini.google.com)
