# 0008 · Live group QR scanner

**Status**: In Progress
**Date**: 2026-09-01

## Summary

Replace the simulated group QR viewfinder with a real continuous scanner on Web, Android, and iOS. Keep the current screen design, invite validation, image picker, and manual link entry.

## Context

`ScanQrJoinPage` currently renders `_ViewfinderPlaceholder`. It never requests a camera, so the browser and mobile operating systems correctly show no camera permission prompt.

The existing page already defines the trusted flow after detection. It extracts the invite code, validates its length, calls `PreviewInviteUseCase`, and returns a preview `GroupEntity` to the caller.

## Requirements

1. `AC-1`: Opening the page starts the rear camera and shows its live preview on Web, Android, and iOS when permission is granted.
2. `AC-2`: The scanner accepts QR codes only and sends the first usable raw value through the existing invite validation flow.
3. `AC-3`: While one result is being validated, duplicate detections do not start more backend requests.
4. `AC-4`: An invalid QR or backend preview failure shows the existing error feedback and allows scanning to continue.
5. `AC-5`: A valid invite stops scanning and returns the preview group through the existing navigation contract.
6. `AC-6`: The flash control operates the real torch when supported. Unsupported devices keep the action safe without crashing.
7. `AC-7`: Image selection and manual link entry remain available as fallback paths.
8. `AC-8`: Camera denial or initialization failure shows a clear error state with a retry action.

## Decision

Use `mobile_scanner` version 7.4 or compatible 7.x. It provides continuous QR detection through CameraX and ML Kit on Android, AVFoundation and Apple Vision on Apple platforms, and BarcodeDetector with ZXing fallback on Web.

Reuse the current page composition and overlay. Put `MobileScanner` behind the existing controls, constrain detection to `BarcodeFormat.qrCode`, and route detections through one guarded handler.

No database, backend API, or domain model changes are required.

## Feature design

The scanner owns one `MobileScannerController`. The page observes controller state for permission, running, torch, and error feedback. Detection pauses logically through `_isDecoding`; invalid results release the guard, while a valid result leaves the scanner stopped as navigation closes the page.

The camera preview fills the existing background. The current corner frame and scan line remain above it. If startup fails, the viewfinder displays the reason and a retry button without removing the image and link fallbacks.

## Build plan

- [x] Add `mobile_scanner` and confirm platform camera declarations.
- [x] Replace `_ViewfinderPlaceholder` with the live scanner and retained overlay.
- [x] Connect detection, duplicate suppression, retry, torch state, and disposal to the existing page flow.
- [x] Add unit and widget regression coverage for preview, detection guarding, fallback controls, and errors.
- [x] Run Flutter analysis, the full test suite, a Web build, and an Android debug build.

## Consequences

The Android bundle grows because the default scanner includes ML Kit. Web camera use still requires HTTPS or `localhost`. Torch availability differs by browser and hardware.

## Follow-up

Physical camera verification remains required on one Android device, one iOS device, and a supported desktop or mobile browser.

## Rationale

The source file already named `MobileScanner` as the intended replacement. Reusing that choice gives real time scanning on every target platform without maintaining a custom frame capture and QR decoding loop.

## Options considered

The existing `camera` package plus periodic still image decoding was rejected because it would repeatedly encode full images, add latency, and duplicate lifecycle work. Keeping image only scanning was rejected because it does not satisfy the live camera screen.
