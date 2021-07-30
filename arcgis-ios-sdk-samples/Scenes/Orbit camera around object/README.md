# Orbit camera around object

Fix the camera to point at and rotate around a target object.

![Image of orbit camera around object](orbit-camera-around-object.png)

## Use case

The orbit geoelement camera controller provides control over the following camera behaviors:

* automatically track the target
* stay near the target by setting a minimum and maximum distance offset
* restrict where you can rotate around the target
* automatically rotate the camera when the target's heading and pitch changes
* disable user interactions for rotating the camera
* animate camera movement over a specified duration
* control the vertical positioning of the target on the screen
* set a target offset (e.g.to orbit around the tail of the plane) instead of defaulting to orbiting the center of the object

## How to use the sample

The sample loads with the camera orbiting an airplane model. The camera is preset with a restricted camera heading and pitch, and a limited minimum and maximum camera distance set from the plane. The position of the plane on the screen is also set just below center.

Use the sliders to adjust the camera heading and the plane's pitch. When not in Cockpit view, the plane's pitch will change independently to that of the camera pitch. Toggle on the switch to allow zooming in and out with the mouse/keyboard; when the switch is off, the user won't be able to adjust with the camera distance.

Tap the "Cockpit view" button to offset and fix the camera into the cockpit of the airplane. Tap the "Center view" button to exit cockpit view mode and fix the camera controller on the center of the plane.

## How it works

1. Instantiate an `AGSOrbitGeoElementCameraController` object.
2. Set the camera controller to the scene view.
3. Set the heading, pitch and distance properties for the camera controller.
4. Set the minimum and maximum angle of heading and pitch, and minimum and maximum distance for the camera.
5. Set the distance from which the camera is offset from the plane.
6. Set the `targetVerticalScreenFactor` property to determine where the plane appears in the scene.
7. Animate the camera to the cockpit using `AGSOrbitGeoElementCameraController.setTargetOffsetX(_:targetOffsetY:targetOffsetZ:duration:completion:)`.
8. Set `isCameraDistanceInteractive` if the camera distance will adjust when zooming or panning using mouse or keyboard (default is true).
9. Set `isAutoPitchEnabled` if the camera will follow the pitch of the plane (default is true).

## Relevant API

* AGSOrbitGeoElementCameraController

## Tags

3D, camera, object, orbit, rotate, scene