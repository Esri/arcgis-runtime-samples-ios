# Route around barriers

Find a route that reaches all stops without crossing any barriers.

![Route around barriers](route-around-barriers-1.jpg)
![Directions for route around barriers](route-around-barriers-2.jpg)

## Use case

You can define barriers to avoid unsafe areas, for example flooded roads, when planning the most efficient route to evacuate a hurricane zone. When solving a route, barriers allow you to define portions of the road network that cannot be traversed. You could also use this functionality to plan routes when you know an area will be inaccessible due to a community activity like an organized race or a market night.

In some situations, it is further beneficial to find the most efficient route that reaches all stops, reordering them to reduce travel time. For example, a delivery service may target a number of drop-off addresses, specifically looking to avoid congested areas or closed roads, arranging the stops in the most time-effective order.

## How to use the sample

Tap 'Add stop' to add stops to the route. Tap 'Add barrier' to add areas that can't be crossed by the route. Tap 'Route' to find the route and display it. Tap the settings button to toggle preferences like find the best sequence or preserve the first or last stop. Additionally, tap the directions button to view a list of the directions. 

## How it works

1. Create the route task by calling `AGSRouteTask(url:)` with the URL to a Network Analysis route service.
2. Get the default route parameters for the service by calling `AGSRouteTask.getDefaultParameters`.
3. When the user adds a stop, add it to the route parameters.
    i. Normalize the geometry; otherwise the route job would fail if the user included any stops over the 180th degree meridian.
    ii. Get the name of the stop by counting the existing stops - `.stopGraphicsOverlay.graphics.index(of:) + 1`.
    iii. Create a composite symbol for the stop. This sample uses a blue marker and a text symbol.
    iv. Create the graphic from the geometry and the symbol.
    v. Add the graphic to the stops graphics overlay.
4. When the user adds a barrier, create a polygon barrier and add it to the route parameters.
    i. Normalize the geometry (see **3i** above).
    ii. Buffer the geometry to create a larger barrier from the tapped point by calling `AGSGeometryEngine.bufferGeometry(geometry:byDistance:)`.
    iii. Create the graphic from the geometry and the symbol.
    iv. Add the graphic to the barriers overlay.
5. When ready to find the route, configure the route parameters.
    i. Set the `ReturnStops` and `ReturnDirections` to `true`.
    ii. Create an `AGSStop` for each graphic in the stops graphics overlay. Add that stop to a list, then call `_routeParameters.setStops(stops:)`.
    iii. Create a `AGSPolygonBarrier` for each graphic in the barriers graphics overlay. Add that barrier to a list, then call `_routeParameters.setPolygonBarriers(polygonBarriers:)`.
    iv. If the user will accept routes with the stops in any order, set `FindBestSequence` to `true` to find the most optimal route.
    v. If the user has a definite start point, set `AGSRouteParameters.preserveFirstStop` to `true`.
    vi. If the user has a definite final destination, set `AGSRouteParameters.preserveLastStop` to `true`.
6. Calculate and display the route.
    i. Call `_routeTask.solveRoute(with:completion:)` to get an `AGSRouteResult`.
    ii. Get the first returned route by calling `AGSRouteResult.routes.first()`.
    iii. Get the geometry from the route as a polyline by accessing the `_.routeGeometry` property.
    iv. Create a graphic from the polyline and a simple line symbol.
    v. Display the steps on the route, available from `_.directionManeuvers`.

## Relevant API

* AGSDirectionManeuver
* AGSPolygonBarrier
* AGSRoute
* AGSRoute.directionManeuvers
* AGSRoute.routeGeometry
* AGSRouteParameters.clearPolygonBarriers
* AGSRouteParameters.findBestSequence
* AGSRouteParameters.preserveFirstStop
* AGSRouteParameters.preserveLastStop
* AGSRouteParameters.returnDirections
* AGSRouteParameters.returnStops
* AGSRouteParameters.setPolygonBarriers
* AGSRouteResult
* AGSRouteResult.routes
* AGSRouteTask
* AGSStop
* AGSStop.Name

## About the data

This sample uses an Esri-hosted sample street network for San Diego.

## Tags

barriers, best sequence, directions, maneuver, network analysis, routing, sequence, stop order, stops
