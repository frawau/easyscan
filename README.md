# easyscan

A simple scanning application.

## Why another scanning application?

Well there are a lot of scanning applications out there.  I am sure they are fine,
but I needed something both simpler and more flexible.

I am currently working on a project managing endurance races. At this time, it is
not meant to handle timing, but time will tell right?

So what we need is handling driver changes, and keeping track of how long each driver
spend on track. To that effect, we generate a card for each driver that has a QR code.

The QR code needs to be scanned when a team sends a driver for a driver change, and when
a driver exits the kart to indicate the end of her/his session and the start of the
session of the other driver. 

So the scanning application simply reads the QR code and sends the content to an API endpoint.

EasyScan works like this:
 - Login with a username, password, and the URL of the API login endpoint.
 - If login is successful, an authorisation token and a URL are returned.
 - Scans send the payload to the URL that was received.

While not strictly necessary, we want to distinguish between driver queue scanning 
(drivers waiting for a change, there can be more than there are pitlanes available.)
and the scan for the actual driver change. 

## Not very useful is it?

Well it works for the go-kart race project. It could also be used to quickly add scanning
stations or temporarily replace disabled scanning stations. The API is easy to implement.

## Is that all?

By embedding a dictionary with 2 keys, info and data, in the QR code, you could setup
2 step scanning. First the QR code is scanned and the value of the info key is displayed.
The operator can select Cancel or Ok. If Ok, the fyll content of the QR code is sent.

## My first phone application

This project is my first phone application. To wtite it, I used Gemini and Cloude AI.

I used VS code for handling code, compilation Android debugging etc. 

This is a Flutter application, here are some Flutter resources: 
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

The scanner is a nice Flutter library, [mobile_scanner]()https://github.com/juliansteenbakker/mobile_scanner)
