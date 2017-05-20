## Mined Minds Mentoring iOS App ##

An iOS wrapper app for the Mined Minds Mentoring website developed using Xcode 8 and Swift 3, with Google Firebase integration for secure authentication and push notification support.

Highlights include:

1. Support for three login methods:
	- username/password authentication
	- Facebook login
	- Google login
2. Auto-login via selected login method on app launch
3. Native slide menu for site navigation
4. Push notifications

----------

## Screenshots ##

[Login Screen](http://imgur.com/VwhPxdm "Login Screen")

[Slide Menu](http://imgur.com/cjiCxMc "Slide Menu")

[Push Notification](http://imgur.com/X8cfg4e "Push Notification")

----------

## Prerequisites for Installing the App ##

1. iOS version 10.3+
2. TestFlight iOS app
3. An invitation from TestFlight to install the app

**Please note that the Mined Minds Mentoring iOS app is currently being deployed via TestFlight.**  As a result, anyone looking to run the app must be set up as a tester via Mined Minds' iTunes Connect account. 

For assistance with being set up as a tester, please contact John Verbosky.

----------

## Installing the App ##

1. Launch the TestFlight app from the desired iOS device.
2. Select **INSTALL** for the Mined Minds Mentoring app.
3. Once the app has been installed, **INSTALL** will change to **OPEN**.

----------

## Push Notification and Login Setup ##

1. Tap the Mined Minds Mentoring app to launch.
2. The first time the app is launched, a prompt to enable push notifications will appear:

	*"Mined Minds Mentoring" Would Like to Send You Notifications*

	- Select **Allow** to enable push notifications for the app.
	- Select **Don't Allow** to disable notifications for the app.

	Note that notification settings can be adjusted later via the iOS **Settings** screen.

3. On the **Sign In** screen, sign in using **one** of the available methods:

	- Usename/password authentication
		1. If signing in for the first time, tap the **Register** button.
		2. Enter the email address and password associated with your Mined Minds Mentoring account.
		3. Tap the **Sign In** button below the password field to sign in.  
	
	- Google login
		1.  Tap the Google **Sign In** button at the bottom of the screen.
		2.  Select the Google account that you want to sign in with.  

	- Facebook login
		1. Tap the **Continue with Facebook** button at the bottom of the screen.
		2. On the **Log in With Facebook** screen, select the **Continue as "name"** button.

----------

**Please note that only one email address per login method is supported.**

For example, if you log in with name@place.com using the Google login, you will not be able to log in with name@place.com using the Facebook login or username/password authentication. 

----------

## Auto-Login and Logging Out ##

Once you have successfully logged in to the Mined Minds Mentoring app, it will open the Mined Minds Mentoring website.  Until you actively log out, the app will use the selected login method to automatically log in to the website each time the app is launched.

To log out from the Mined Minds Mentoring app, do the following:

1. Tap the upper left menu button (three stacked lines).
2. On the slide menu, select **Log Out**.
3. The app will return to the **Sign In** screen.

	Note that if you used the Facebook login, a further step is required to completely log out:

	- Tap the **Log out** Facebook button at the bottom of the screen.

----------

## Navigating the Mined Minds Mentoring Site ##

Once you have successfully logged in to the Mined Minds Mentoring app, you can use the app's slide menu to navigate the site.

1. Tap the upper left menu button (three stacked lines).
2. On the slide menu, select the desired page (Mentors, Mentees, Requests).

----------

## Push Notifications ##

If push notifications are enabled for the Mined Minds Mentoring app, you will receive them when the app is not active.

----------
