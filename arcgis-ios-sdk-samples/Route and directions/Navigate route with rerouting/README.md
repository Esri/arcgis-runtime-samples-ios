# Navigate route with rerouting

Navigate between two points and dynamically recalculate an alternate route when the original route is unavailable.

![Image of navigate route with rerouting](navigate-route-rerouting.png)

## Use case

While traveling between destinations, field workers use navigation to get live directions based on their locations. In cases where a field worker makes a wrong turn, or if the route suggested is blocked due to a road closure, it is necessary to calculate an alternate route to the original destination.

## How to use the sample

Tap "Navigate" to simulate traveling and to receive directions from a preset starting point to a preset destination. Observe how the route is recalculated when the simulation does not follow the suggested route. Tap "Recenter" to reposition the viewpoint. Tap "Reset" to start the simulation from the beginning.

## How it works

1. Create an `AGSRouteTask` using local network data.
2. Generate default `AGSRouteParameters` using `AGSRouteTask.defaultRouteParameters(completion:)`.
3. Set `returnRoutes`, `returnStops`, and `returnDirections` on the parameters to `true`.
4. Add `AGSStop`s to the parameters' array of `stops` using `AGSRouteParameters.setStops(_:)`.
5. Solve the route using `AGSRouteTask.solveRoute(with:completion:)` to get an `AGSRouteResult`.
6. Create an `AGSRouteTracker` using the route result, and the index of the desired route to take.
7. Enable rerouting in the route tracker using `AGSRouteTracker.enableRerouting(with:routeParameters:strategy:visitFirstStopOnStart:completion:)`. Pass `AGSReroutingStrategy.toNextWaypoint` as the value of `strategy` to specify that in the case of a reroute, the new route goes from present location to next waypoint or stop.
8. Implement `AGSLocationChangeHandlerDelegate.locationDataSource(_:locationDidChange:)` to track the location of the device and update the route tracking status.
9. Implement `AGSRouteTrackerDelegate.routeTracker(_:didUpdate:)` to be notified of `AGSTrackingStatus` changes, and use them to display updated route information. `AGSTrackingStatus` includes a variety of information on the route progress, such as the remaining distance, remaining geometry or traversed geometry (represented by an `AGSPolyline`), or the remaining time (`Double`), amongst others.
10. Implement `AGSRouteTrackerDelegate.routeTracker(_:didGenerateNewVoiceGuidance:)` to be notified of new voice guidances. From the voice guidance, get the `AGSVoiceGuidance.text` representing the directions and use a text-to-speech engine to output the maneuver directions.
11. You can also query the tracking status for the current `AGSDirectionManeuver` index by retrieving that maneuver from the `AGSRoute` and getting its direction text to display in the GUI.
12. To establish whether the destination has been reached, get the `destinationStatus` from the tracking status. If the destination status is `reached` and the `remainingDestinationCount` is 1, you have arrived at the destination and can stop routing. If there are several destinations on your route and the remaining destination count is greater than 1, switch the route tracker to the next destination.

## Relevant API

* AGSDestinationStatus
* AGSDirectionManeuver
* AGSLocation
* AGSLocationDataSource
* AGSReroutingStrategy
* AGSRoute
* AGSRouteParameters
* AGSRouteTask
* AGSRouteTracker
* AGSRouteTrackerLocationDataSource
* AGSSimulatedLocationDataSource
* AGSStop
* AGSVoiceGuidance

## Offline data

The [Navigate a Route GPX Track](https://arcgisruntime.maps.arcgis.com/home/item.html?id=91e7e6be79cc4d2f8416eff867674c1e) provides a simulated path for the device to demonstrate routing while traveling.

## About the data

The route taken in this sample goes from the San Diego Convention Center, site of the annual Esri User Conference, to the Fleet Science Center, San Diego.

## Additional information

The route tracker will start a rerouting calculation automatically as necessary when the device's location indicates that it is off-route. The route tracker also validates that the device is "on" the transportation network, if it is not (e.g. in a parking lot) rerouting will not occur until the device location indicates that it is back "on" the transportation network.

## Tags

directions, maneuver, navigation, route, turn-by-turn, voice
