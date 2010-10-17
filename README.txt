
 Astral Projection
===================


0. Introduction

Astral Projection (from hereon aka 'AP') is an extension to the iOS CoreLocation framework which can make testing of location-aware iPhone/iPad applications easier.


1. The name

From Wikipedia: "Astral projection (or astral travel) is an interpretation of any form of out-of-body experience (OBE) that assumes the existence of an 'astral body' separate from the physical body and capable of travelling outside it."


2. What is it good for?

Generally, apps that use location data can only be tested well when deployed on the device. The simulator has limited or no facilities for returning GPS coordinates (particularly, the iPhone simulator returns one hard-coded location), and the hardware builds worth equally little if the wandering "range" is limited to the length of the USB cable (e.g. in case of on-device debugging). But even if you are fine with deploying, how would you test use cases which involve motion and you don't get a damn fix in the whole office? This is when AP enters the scene.

Astral Projection is a set of tools which allow you to generate fake location-related data that normally comes from the underlying hardware such as GPS or wireless triangulation. AP is bundled with a couple of data sources which you can use right away, or, should you require a custom one, you can also add your own modules complying with a simple interface. 


3. How does it work?

AP consists of a core and an optional set of data sources. The main class is APLocationManager which is a subclass of CLLocationManager and is meant to replace the latter, at least when instantiating. Due to subclassing, code which has used CLLocationManager can continue doing so without any change whatsoever.

APLocationManager takes over methods of its ancestor and lets the data source provide an alternative logic for that functionality, which basically makes this class a dispatcher of data source callbacks as if they were coming from CLLocationManager. Hence APLocationManager itself does not require the presence of any location-related hardware.

Location data sources are classes conforming to the APLocationDataSource protocol. Data sources take a reference to a delegate of APLocationDataDelegate kind (normally the location manager) which they notify about location changes appropriately, according to their own implementation. Similarly, heading data sources comply with APHeadingDataSource and are responsible for handing over heading information.

Currently AP comes with two built-in data sources:

 * APGPXDataSource (location only): loads a GPX file and uses its waypoints, routes or tracks as location change event source. "Playback" can be speeded up/slown down by means of a time scale. If the point set does not have timestamps, it is also possible to emit the points at a given frequency.

* APAgentDataSource (location + heading): uses the location and heading data of a "field agent", transmitted through the network. The agent can be any iOS device with the APAgent app installed. APAgent sends its location information in UDP packets to a configurable IP address-port where the APAgentDataSource is supposed to be listening. APAgentDataSource then reports the extracted location data to the location manager.


4. Known limitations

As of now, AP is limited to location and heading data, that is, no significant-change, no regions, no nothing. In the future this may change if I happen to need that stuff or if I find an enthusiastic volunteer to code it for everyone's sake. :)


5. Installation

Here are some guidelines for setting up AP in your project:
- check out the latest revision from trunk (recommended to do so even if downloading the zip is easier)
- add the Core files to your project 
- add one or more data sources (note that APAgentDataSource depends on JSON, if you add this data source you have to add JSON as well-- see the ThirdParty folder)

Some hints on how to integrate it in your code (see APHost sample app for details):
- in the code where you instantiated CLLocationManager, replace it with APLocationManager
- instantiate and set up the desired data source(s), passing the location manager to it as delegate
- call startUpdatingLocation/startUpdatingHeading on the location manager, then fire off the data source


6. Contact

In case of doubts, bug reports or feature requests, you are welcome to visit the project home page at:

http://sourceforge.net/projects/apios/



Enjoy!

lvsti



