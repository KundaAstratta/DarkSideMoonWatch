import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

class DarkSideMoonWatchView extends WatchUi.WatchFace {
    // Variables pour l'animation de pulsation (à l'extérieur de la fonction)
    var pulseSize = 0;
    var pulseDirection = 1; // 1 pour augmenter, -1 pour diminuer
    var explosionPixels = []; // Tableau pour stocker les pixels de l'explosion

    // 2 pi
    var TWO_PI = Math.PI * 2;
    //angle adjust for time hands
    var ANGLE_ADJUST = Math.PI / 2.0;
    //is in sleep mode
    var isInSleepMode = false;
    //theme
    var theme = 1;

    private var _centerX as Number = 0;
    private var _centerY as Number = 0;
    private var _radius as Number = 0;
    private var _radiusMarkers as Number = 0;

    function initialize() {
        WatchFace.initialize();
    }

    function getRandom() {
        var randomNumber = Math.rand()/32768.0/32768.0 - 1 ;
        if (randomNumber < 0) {
            System.print("ici");
            System.println(-randomNumber);
            return -randomNumber;
        }
        System.println("là");
        System.println(randomNumber);
        return randomNumber;
       
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        _centerX = dc.getWidth() / 2 ;
        _centerY = dc.getHeight() / 2 ;
        _radius = (_centerX < _centerY ? _centerX : _centerY) - 20;
        _radiusMarkers = dc.getWidth() /2;


        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        //isInSleepMode = false;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get the current time
        var now = System.getClockTime();
        var hour = now.hour;
        var min = now.min;
        var sec = now.sec;
   
        // to draw the line time
        var hour_fraction = min / 60.0;
        var minute_angle = hour_fraction * TWO_PI;
        var hour_angle = ((hour % 12 + hour_fraction) / 12.0) * TWO_PI;
        var seconde_angle = sec / 60.0 * TWO_PI;
        
        // compensate the starting position
        minute_angle -= ANGLE_ADJUST;
        hour_angle -= ANGLE_ADJUST;
        seconde_angle -= ANGLE_ADJUST;

        // center  
        var center_x = dc.getWidth() / 2;
        var center_y = dc.getHeight() / 2;
        var diameter = dc.getWidth() ;
        var radius = diameter / 2 ;


        //today and moon phase
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        
        var notificationCount = System.getDeviceSettings().notificationCount;
        var notificationExist = false;
        if (notificationCount == 0) {
            notificationExist = false;
        } else {
            notificationExist = true;
        }
        var pictureNotification = Properties.getValue("PictureNotification"); 

        var phoneConnected = System.getDeviceSettings().phoneConnected;
        var picturePhoneNotConnected = Properties.getValue("PicturePhoneNotConnected");

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        var battery = System.getSystemStats().battery;

        theme = Properties.getValue("Theme");


        //TEST
        //isInSleepMode =  true;
        //TEST


        var isNightMode = Properties.getValue("NightMode"); 

        // Mettre à jour la taille de la pulsation
        pulseSize += pulseDirection*5;
        if (pulseSize >= 20) { // Ajuster la valeur maximale de la pulsation
            pulseDirection = -1;

            // Créer les pixels de l'explosion
            createExplosionPixels(center_x, center_y - radius * 0.65, 10); 
            
        } else if (pulseSize <= 0) {
            pulseDirection = 1;

            explosionPixels = []; // Réinitialiser les pixels d'explosion

        }

        //Main Here

        //Noght mode ?
        if (isWithinTimeRange(hour,min, isNightMode)) {
            //BasicTheme
            if (isBasicTheme(theme)) {
                drawHourandMinutesHandNight(dc,center_x,center_y,radius,hour_angle,minute_angle);   
            } 
            
            //An other theme 
            if (!isBasicTheme(theme)) {
                drawHourandMinutesHandAdventureNight(dc,center_x,center_y,radius,hour_angle,minute_angle);
            }         
        } 
        
        //To calculate if is normal mode or night mode
        if (!isWithinTimeRange(hour,min,isNightMode)) {

            //Sleep Mode ?
            if (isInSleepMode) {
                //Basic Theme
                if (isBasicTheme(theme)) {
                    drawStarField(dc);
                    drawHourandMinutesHand(dc,center_x,center_y,radius,hour_angle,minute_angle);
                }
                //An other theme 
                if (!isBasicTheme(theme)) {
                    drawStarField(dc);
                    drawHourandMinutesHandAdventure(dc,center_x,center_y,radius,hour_angle,minute_angle);
                    if (theme == 4) {
                        drawStarField(dc);
                        drawHourandMinutesHandAdventureNight(dc,center_x,center_y,radius,hour_angle,minute_angle);
                    }
                }

            }
            // Day mode - Begin
            if (!isInSleepMode) {

                if (battery >=20) {  

                    if (!notificationExist && phoneConnected)  {   
                        //normalWatchFace(dc,moonNumber, center_x,center_y,radius,hour_angle,minute_angle,today,sec);
                        normalWatchFace(dc, center_x,center_y,radius,hour_angle,minute_angle,today,sec);

                    }
                    
                    if (notificationExist && phoneConnected)  {  
                        if (pictureNotification) { 
                            normalLevelBatteryAndNotificationExistAndPhoneConnected(dc, center_x,center_y,radius,hour, min);
                        }
                        if (!pictureNotification) {
                            //normalWatchFace(dc,moonNumber, center_x,center_y,radius,hour_angle,minute_angle,today,sec);
                            normalWatchFace(dc, center_x,center_y,radius,hour_angle,minute_angle,today,sec);  
                            iconNotification(dc, center_x,center_y,radius);
                        }
                    }  

                    if (!phoneConnected)  {  
                        if (picturePhoneNotConnected) {
                            normalLevelBatteryAndPhoneNotConnected(dc, center_x,center_y,radius,hour, min);
                        }
                        if (!picturePhoneNotConnected) {
                            //normalWatchFace(dc,moonNumber, center_x,center_y,radius,hour_angle,minute_angle,today,sec);
                            normalWatchFace(dc, center_x,center_y,radius,hour_angle,minute_angle,today,sec);       
                            iconBluetooth(dc,center_x,center_y,radius);
                        }
                    }  

                }

                if ((battery < 20) && (battery > 10) ) {  
                    ifBatteryBetweenTenAndTwenty(dc,battery, center_x,center_y, radius, hour, min);
                }

                if (battery <= 10) {     
                    ifBatteryLessThanTen(dc,battery, center_x,center_y, radius, hour, min);
                }

            }
            // Day mode - end

        }
           
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        isInSleepMode = false;
        WatchUi.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isInSleepMode = true;
        WatchUi.requestUpdate();
    }

    function iconBluetooth(dc, center_x,center_y,radius) {
        //var pulsationNotification = Properties.getValue("PulsationNotification");
        var iconX = center_x;
        var iconY = center_y + radius * 0.65;
        var iconSize = 20;
        // Dessiner le contour noir du cercle
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(iconX, iconY, iconSize / 2);

        // Dessiner le cercle rouge par-dessus le contour
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(iconX, iconY, iconSize / 2);

    }

    function iconNotification(dc, center_x, center_y, radius) {
        var pulsationNotification = Properties.getValue("PulsationNotification");
        var iconX = center_x;
        var iconY = center_y - radius * 0.65;
        var iconSize = 20;
        if (pulsationNotification) {
            iconSize = 5 + pulseSize;
        }
        var outlineWidthNotification = 2;

        // Si l'icône est en train d'exploser
        if (pulsationNotification) {
            if (explosionPixels.size() > 0) {
                drawExplosion(dc, explosionPixels);
                return; // Ne pas dessiner l'icône normale
            }
        }

        // Dessiner le contour noir du cercle
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(iconX, iconY, iconSize / 2 + outlineWidthNotification);

        // Dessiner le cercle rouge par-dessus le contour
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(iconX, iconY, iconSize / 2);
    }

    function drawExplosion(dc, pixels) {
        var i = 0;
        while (i < pixels.size()) {
            var pixel = pixels[i];
            pixel["x"] += pixel["dx"];
            pixel["y"] += pixel["dy"];
            pixel["size"] -= 0.1; // Diminuer la taille
            pixel["opacity"] -= 10; // Diminuer l'opacité

            // Dessiner le pixel avec l'opacité actuelle
            dc.setColor(Graphics.COLOR_WHITE, pixel["opacity"]); 
            dc.fillCircle(pixel["x"], pixel["y"], pixel["size"]);

            // Supprimer le pixel s'il est trop petit ou transparent
            if (pixel["size"] <= 0 || pixel["opacity"] <= 0) {
                pixels.remove(i);
            } else {
                i++;
            }
        }
    }

    function createExplosionPixels(x, y, count) {
        explosionPixels = new [count];
        for (var i = 0; i < count; i++) {
            var pixel = {};
            pixel["x"] = x + (Math.rand() % 10 - 5); // Ajouter un décalage aléatoire en x
            pixel["y"] = y + (Math.rand() % 10 - 5); // Ajouter un décalage aléatoire en y
            pixel["dx"] = (Math.rand() % 10 - 5) / 2; // Augmenter la vitesse en x
            pixel["dy"] = (Math.rand() % 10 - 5) / 2; // Augmenter la vitesse en y
            pixel["size"] = 5; // Augmenter la taille initiale
            pixel["opacity"] = 255;
            explosionPixels[i] = pixel;
        }
    }

    //function normalWatchFace(dc,moonNumber,center_x,center_y,radius,hour_angle,minute_angle, today, sec) {
    function normalWatchFace(dc,center_x,center_y,radius,hour_angle,minute_angle, today, sec) {
        
        var skystarsbackground = Properties.getValue("SkyStars");
        if (skystarsbackground) {
            // Background night/blue
            dc.setColor(Graphics.COLOR_TRANSPARENT, 0x000040); // Bleu nuit foncé
            drawConcentricBackground(dc);
            drawStarField(dc);
            dc.clear();

        }

        //Background Moon
        var Moon = WatchUi.loadResource(Rez.Drawables.whitemoon) ;
        dc.drawBitmap(center_x, center_y, Moon) ;
        var redmoonbackground = Properties.getValue("RedMoon");
        if (redmoonbackground) {
            Moon = WatchUi.loadResource(Rez.Drawables.redmoon) ;
            dc.drawBitmap(center_x, center_y, Moon) ;
        }

        // Dessiner les tirets pour les heures spécifiées
        var isShowMarkers = Properties.getValue("ShowMarkers"); 
        if (isShowMarkers) {
            // MODIFICATION: Appel de la nouvelle fonction sans les anciens arguments
            drawHourMarkers(dc);
        }

        //Moon phase
        //showMoonPhase(moonNumber, dc, center_x + center_x / 3 , center_y + center_y / 3);
         drawMoonPhase(dc);

        // Top Arc
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); // Contour noir en premier
        dc.setPenWidth(7); // Dessiner le contour plus large
        dc.drawArc(center_x, center_y, radius * 0.74, Graphics.ARC_COUNTER_CLOCKWISE, 60, 120);
        dc.drawArc(center_x, center_y, radius * 0.77, Graphics.ARC_COUNTER_CLOCKWISE, 70, 110);

        // Dessiner les arcs blancs par-dessus le contour noir
        dc.setPenWidth(3); 
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(center_x, center_y, radius * 0.74, Graphics.ARC_COUNTER_CLOCKWISE, 60, 120);
        dc.drawArc(center_x, center_y, radius * 0.77, Graphics.ARC_COUNTER_CLOCKWISE, 70, 110);

        // Left Arc
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); // Contour noir
        dc.setPenWidth(7);
        dc.drawArc(center_x, center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, 150, 210);

        // Dessiner l'arc de couleur par-dessus
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        if (!isBasicTheme(theme)) {
            if (theme == 2) {
                dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 3) {
                dc.setColor(0x7FFF00, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 4) {
                dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            }
        }
        dc.drawArc(center_x, center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, 150, 210);

        // Right Arc
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); // Contour noir
        dc.setPenWidth(7);
        dc.drawArc(center_x, center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, -30, 30);

        // Dessiner l'arc blanc par-dessus
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(center_x, center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, -30, 30);

        // Bottom Arc
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); // Contour noir
        dc.setPenWidth(7);
        dc.drawArc(center_x, center_y, radius * 0.74, Graphics.ARC_COUNTER_CLOCKWISE, 240, 300);
        dc.drawArc(center_x, center_y, radius * 0.77, Graphics.ARC_COUNTER_CLOCKWISE, 250, 290);

        // Dessiner les arcs blancs par-dessus
        dc.setPenWidth(3); 
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(center_x, center_y, radius * 0.74, Graphics.ARC_COUNTER_CLOCKWISE, 240, 300);
        dc.drawArc(center_x, center_y, radius * 0.77, Graphics.ARC_COUNTER_CLOCKWISE, 250, 290);

        //Date
        var isShowDate = Properties.getValue("ShowDate"); 
        //var DateColor = Properties.getValue("DateColor") ; 

        if (isShowDate) {
            drawCurvedMonth(dc);
            drawSystemInfo(dc); 
        }     

        //Second Right Arc ; seconds
        var secArc = sec / 60.0 * 60.0;
        var drawSecArc = -30 + secArc; 
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_RED);
        if (!isBasicTheme(theme)) {
            if (theme == 2) {
                dc.setColor(0xAA5500, 0xAA5500);
            }
            if (theme == 3) {
                dc.setColor(0x7FFF00, 0x7FFF00);
            }
            if (theme == 4) {
                dc.setColor(0xFF0000,0xFF0000);
            }
        }


        dc.drawArc(center_x,center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, drawSecArc, 30);

        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
        dc.drawText(center_x + radius * 0.65, center_y , Graphics.FONT_SYSTEM_XTINY,  sec +"s", Graphics.TEXT_JUSTIFY_CENTER);
    
        
        //Second Left Arc : battery
        var batteryPercent = System.getSystemStats().battery / 100.0 * 60.0;
        var drawBattery = 150 + batteryPercent;
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_RED);
        if (!isBasicTheme(theme)) {    
            dc.setColor(0x999999,0x999999);
        }
        dc.drawArc(center_x, center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, drawBattery,210);

        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
        dc.drawText(center_x - radius * 0.65, center_y , Graphics.FONT_SYSTEM_XTINY,  System.getSystemStats().battery.toNumber() +"%", Graphics.TEXT_JUSTIFY_CENTER);

        //Basic Theme
        if (isBasicTheme(theme)) {    
            drawHourandMinutesHand(dc,center_x,center_y,radius,hour_angle,minute_angle);
        }   
        //Other theme
        if (!isBasicTheme(theme)) {
            drawHourandMinutesHandAdventure(dc,center_x,center_y,radius,hour_angle,minute_angle);
            if (theme == 4) {
                drawHourandMinutesHandAdventureNight(dc,center_x,center_y,radius,hour_angle,minute_angle);
            }
        }
        //draw seconde hand only for adventure theme
        //Other theme
        if (!isBasicTheme(theme)) {    
            drawSecondHandAdventure(dc,center_x,center_y,radius, sec / 60.0 * TWO_PI - ANGLE_ADJUST);
        }   
    }

    function normalLevelBatteryAndNotificationExistAndPhoneConnected(dc, center_x,center_y,radius,hour, min) {
        var notification = WatchUi.loadResource(Rez.Drawables.notification) ;
        dc.drawBitmap(center_x - radius, center_y -radius, notification) ;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (!isBasicTheme(theme)) {
            if (theme == 2) {
                dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 3) {
                dc.setColor(0x7FFF00, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 4) {
                dc.setColor(0xFF0000,Graphics.COLOR_TRANSPARENT);
            }
        }
        dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, hour.format("%02d")+":"+min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
    }

    function normalLevelBatteryAndPhoneNotConnected(dc, center_x,center_y,radius,hour, min) {
        var connected = WatchUi.loadResource(Rez.Drawables.connected) ;
        dc.drawBitmap(center_x - radius, center_y -radius, connected) ;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (!isBasicTheme(theme)) {
            if (theme == 2) {
                dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 3) {
                dc.setColor(0x7FFF00, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 4) {
                dc.setColor(0xFF0000,Graphics.COLOR_TRANSPARENT);
            }
        }
        dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, hour.format("%02d")+":"+min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
    }


    function ifBatteryBetweenTenAndTwenty(dc, battery, center_x, center_y, radius,hour,min) {
        var blackhole = WatchUi.loadResource(Rez.Drawables.blackhole) ;
        dc.drawBitmap(center_x - radius, center_y - radius, blackhole) ;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (!isBasicTheme(theme)) {
            if (theme == 2) {
                dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 3) {
                dc.setColor(0x7FFF00, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 4) {
                dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            }
        }
        dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, hour.format("%02d")+":"+min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
    }

    function ifBatteryLessThanTen(dc,battery, center_x,center_y, radius, hour, min) {
        var creature = WatchUi.loadResource(Rez.Drawables.creature) ;
        dc.drawBitmap(center_x - radius, center_y -radius, creature) ;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (!isBasicTheme(theme)) {
            if (theme == 2) {
                dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 3) {
                dc.setColor(0x7FFF00, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 4) {
                dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            }
        }
        dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, hour.format("%02d")+":"+min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawHourandMinutesHand(dc, center_x, center_y, radius, hour_angle, minute_angle) {
        var handWidth = 4; 
        var outlineWidth = 2; 

        // Aiguille des heures (avec contour blanc)
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(handWidth + outlineWidth * 2);

        var hourHandLength = 0.65 * radius;
        var hourHandBaseOffset = radius * 0.20; 
        var hourHandTipOffset = hourHandLength * 0.70;

        dc.drawLine(
            center_x + hourHandBaseOffset * Math.cos(hour_angle),
            center_y + hourHandBaseOffset * Math.sin(hour_angle),
            center_x + (hourHandBaseOffset + hourHandTipOffset) * Math.cos(hour_angle),
            center_y + (hourHandBaseOffset + hourHandTipOffset) * Math.sin(hour_angle)
        );

        dc.fillCircle(
            center_x + hourHandBaseOffset * Math.cos(hour_angle),
            center_y + hourHandBaseOffset * Math.sin(hour_angle),
            (handWidth + outlineWidth) / 2 
        );
        dc.fillCircle(
            center_x + (hourHandBaseOffset + hourHandTipOffset) * Math.cos(hour_angle),
            center_y + (hourHandBaseOffset + hourHandTipOffset) * Math.sin(hour_angle),
            (handWidth + outlineWidth) / 2 
        );

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (!isBasicTheme(theme)) {    
            dc.setColor(0x999999, Graphics.COLOR_TRANSPARENT);
        }
        dc.setPenWidth(handWidth); 
        dc.drawLine(
            center_x + hourHandBaseOffset * Math.cos(hour_angle),
            center_y + hourHandBaseOffset * Math.sin(hour_angle),
            center_x + (hourHandBaseOffset + hourHandTipOffset) * Math.cos(hour_angle),
            center_y + (hourHandBaseOffset + hourHandTipOffset) * Math.sin(hour_angle)
        );

        dc.fillCircle( 
            center_x + hourHandBaseOffset * Math.cos(hour_angle),
            center_y + hourHandBaseOffset * Math.sin(hour_angle),
            handWidth / 2
        );
        dc.fillCircle(
            center_x + (hourHandBaseOffset + hourHandTipOffset) * Math.cos(hour_angle),
            center_y + (hourHandBaseOffset + hourHandTipOffset) * Math.sin(hour_angle),
            handWidth / 2
        );

        // Aiguille des minutes (avec contour blanc)
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(handWidth + outlineWidth * 2); 

        var minuteHandLength = 0.85 * radius;
        var minuteHandBaseOffset = radius * 0.20; 
        var minuteHandTipOffset = minuteHandLength * 0.80; 

        dc.drawLine(
            center_x + minuteHandBaseOffset * Math.cos(minute_angle),
            center_y + minuteHandBaseOffset * Math.sin(minute_angle),
            center_x + (minuteHandBaseOffset + minuteHandTipOffset) * Math.cos(minute_angle),
            center_y + (minuteHandBaseOffset + minuteHandTipOffset) * Math.sin(minute_angle)
        );

        dc.fillCircle(
            center_x + minuteHandBaseOffset * Math.cos(minute_angle),
            center_y + minuteHandBaseOffset * Math.sin(minute_angle),
            (handWidth + outlineWidth) / 2 
        );
        dc.fillCircle(
            center_x + (minuteHandBaseOffset + minuteHandTipOffset) * Math.cos(minute_angle),
            center_y + (minuteHandBaseOffset + minuteHandTipOffset) * Math.sin(minute_angle),
            (handWidth + outlineWidth) / 2
        );

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        if (!isBasicTheme(theme)) {
            if (theme == 2) {
                dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 3) {
                dc.setColor(0x7FFF00, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 4) {
                dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            }
        }
        dc.setPenWidth(handWidth);
        dc.drawLine(
            center_x + minuteHandBaseOffset * Math.cos(minute_angle),
            center_y + minuteHandBaseOffset * Math.sin(minute_angle),
            center_x + (minuteHandBaseOffset + minuteHandTipOffset) * Math.cos(minute_angle),
            center_y + (minuteHandBaseOffset + minuteHandTipOffset) * Math.sin(minute_angle)
        );

        dc.fillCircle( 
            center_x + minuteHandBaseOffset * Math.cos(minute_angle),
            center_y + minuteHandBaseOffset * Math.sin(minute_angle),
            handWidth / 2
        );
        dc.fillCircle(
            center_x + (minuteHandBaseOffset + minuteHandTipOffset) * Math.cos(minute_angle),
            center_y + (minuteHandBaseOffset + minuteHandTipOffset) * Math.sin(minute_angle),
            handWidth / 2
        );
    }

    // Draw second here
    function drawSecondHandAdventure(dc, center_x, center_y, radius, seconde_angle) {
        var isAdventureSecondHand = Properties.getValue("AdventureSecondHand"); 
        if (isAdventureSecondHand) {
            // Dessiner une ligne noire derrière l'aiguille des secondes
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(5); // Légèrement plus épaisse pour créer l'effet de contour
            dc.drawLine(
                center_x,
                center_y,
                center_x + radius * 0.95 * Math.cos(seconde_angle),
                center_y + radius * 0.95 * Math.sin(seconde_angle)
            );
            if (theme == 2) {
                dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 3) {
                dc.setColor(0x7FFF00,Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 4) {
                dc.setColor(0xFF0000,Graphics.COLOR_TRANSPARENT);
            }
            dc.setPenWidth(3);
            dc.drawLine(
                center_x , 
                center_y , 
                center_x + radius * 0.95 * Math.cos(seconde_angle),
                center_y + radius * 0.95 * Math.sin(seconde_angle)
            );
        }
    }


    function drawHourandMinutesHandAdventure(dc, center_x, center_y, radius, hour_angle, minute_angle) {
        // Draw hour hand with black outline
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(12);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(hour_angle), 
            center_y + radius * 0.20 * Math.sin(hour_angle), 
            center_x + radius * 0.72 * Math.cos(hour_angle),
            center_y + radius * 0.72 * Math.sin(hour_angle)
        );
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.19 * Math.cos(hour_angle),
            center_y + radius * 0.19 * Math.sin(hour_angle),
            7
        );
        dc.fillCircle(
            center_x + radius * 0.73 * Math.cos(hour_angle),
            center_y + radius * 0.73 * Math.sin(hour_angle),
            7
        );

        //draw hour hand
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(
            center_x , 
            center_y , 
            center_x + radius * 0.72 * Math.cos(hour_angle),
            center_y + radius * 0.72 * Math.sin(hour_angle)
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(10);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(hour_angle), 
            center_y + radius * 0.20 * Math.sin(hour_angle), 
            center_x + radius * 0.72 * Math.cos(hour_angle),
            center_y + radius * 0.72 * Math.sin(hour_angle)
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.19 * Math.cos(hour_angle),
            center_y + radius * 0.19 * Math.sin(hour_angle),
            5
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.73 * Math.cos(hour_angle),
            center_y + radius * 0.73 * Math.sin(hour_angle),
            5
        );
        if (theme == 2) {
            dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
        }
        if (theme == 3) {
            dc.setColor(0x7FFF00,Graphics.COLOR_TRANSPARENT);
        }
        if (theme == 4) {
            dc.setColor(0xFF0000,Graphics.COLOR_TRANSPARENT);
        }
        dc.setPenWidth(6);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(hour_angle), 
            center_y + radius * 0.20 * Math.sin(hour_angle), 
            center_x + radius * 0.72 * Math.cos(hour_angle),
            center_y + radius * 0.72 * Math.sin(hour_angle)
        );

        // Draw minute hand with black outline
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(12);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(minute_angle), 
            center_y + radius * 0.20 * Math.sin(minute_angle), 
            center_x + radius * 0.90 * Math.cos(minute_angle),
            center_y + radius * 0.90 * Math.sin(minute_angle)
        );
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.19 * Math.cos(minute_angle),
            center_y + radius * 0.19 * Math.sin(minute_angle),
            7
        );
        dc.fillCircle(
            center_x + radius * 0.91 * Math.cos(minute_angle),
            center_y + radius * 0.91 * Math.sin(minute_angle),
            7
        );

        // draw the minute hand
        dc.setColor((Graphics.COLOR_WHITE), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(
            center_x , 
            center_y ,
            center_x + radius * 0.90 * Math.cos(minute_angle),
            center_y + radius * 0.90 * Math.sin(minute_angle)
        );  
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(10);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(minute_angle), 
            center_y + radius * 0.20 * Math.sin(minute_angle), 
            center_x + radius * 0.90 * Math.cos(minute_angle),
            center_y + radius * 0.90 * Math.sin(minute_angle)
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.19 * Math.cos(minute_angle),
            center_y + radius * 0.19 * Math.sin(minute_angle),
            5
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.91 * Math.cos(minute_angle),
            center_y + radius * 0.91 * Math.sin(minute_angle),
            5
        );
        if (theme == 2) {
            dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
        }
        if (theme == 3) {
            dc.setColor(0x7FFF00,Graphics.COLOR_TRANSPARENT);
        }
        if (theme == 4) {
            dc.setColor(0xFF0000,Graphics.COLOR_TRANSPARENT);
        }
        dc.setPenWidth(6);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(minute_angle), 
            center_y + radius * 0.20 * Math.sin(minute_angle), 
            center_x + radius * 0.90 * Math.cos(minute_angle),
            center_y + radius * 0.90 * Math.sin(minute_angle)
        );

        //center
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x ,
            center_y ,
            10
        );
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x ,
            center_y ,
            7
        );
        if (theme == 2) {
            dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
        }
        if (theme == 3) {
            dc.setColor(0x7FFF00,Graphics.COLOR_TRANSPARENT);
        }
        if (theme == 4) {
            dc.setColor(0xFF0000,Graphics.COLOR_TRANSPARENT);
        }
        dc.fillCircle(
            center_x ,
            center_y ,
            8
        );
        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x ,
            center_y ,
            4
        );        
    }

    function drawHourandMinutesHandNight(dc,center_x,center_y,radius,hour_angle,minute_angle) {
        //draw hour hand
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(hour_angle), 
            center_y + radius * 0.20 * Math.sin(hour_angle), 
            center_x + radius * 0.72 * Math.cos(hour_angle),
            center_y + radius * 0.72 * Math.sin(hour_angle)
        );

        // draw the minute hand
        dc.setColor((Graphics.COLOR_DK_RED), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(minute_angle), 
            center_y + radius * 0.20 * Math.sin(minute_angle),
            center_x + radius * 0.90 * Math.cos(minute_angle),
            center_y + radius * 0.90 * Math.sin(minute_angle)
        );   
    }

    function drawHourandMinutesHandAdventureNight(dc, center_x, center_y, radius, hour_angle, minute_angle) {
        // Draw hour hand with black outline
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(12);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(hour_angle), 
            center_y + radius * 0.20 * Math.sin(hour_angle), 
            center_x + radius * 0.72 * Math.cos(hour_angle),
            center_y + radius * 0.72 * Math.sin(hour_angle)
        );
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.19 * Math.cos(hour_angle),
            center_y + radius * 0.19 * Math.sin(hour_angle),
            7
        );
        dc.fillCircle(
            center_x + radius * 0.73 * Math.cos(hour_angle),
            center_y + radius * 0.73 * Math.sin(hour_angle),
            7
        );

        //draw hour hand
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(
            center_x , 
            center_y , 
            center_x + radius * 0.72 * Math.cos(hour_angle),
            center_y + radius * 0.72 * Math.sin(hour_angle)
        );
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(10);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(hour_angle), 
            center_y + radius * 0.20 * Math.sin(hour_angle), 
            center_x + radius * 0.72 * Math.cos(hour_angle),
            center_y + radius * 0.72 * Math.sin(hour_angle)
        );
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.19 * Math.cos(hour_angle),
            center_y + radius * 0.19 * Math.sin(hour_angle),
            5
        );
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.73 * Math.cos(hour_angle),
            center_y + radius * 0.73 * Math.sin(hour_angle),
            5
        );
        dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(hour_angle), 
            center_y + radius * 0.20 * Math.sin(hour_angle), 
            center_x + radius * 0.72 * Math.cos(hour_angle),
            center_y + radius * 0.72 * Math.sin(hour_angle)
        );

        // Draw minute hand with black outline
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(12);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(minute_angle), 
            center_y + radius * 0.20 * Math.sin(minute_angle), 
            center_x + radius * 0.90 * Math.cos(minute_angle),
            center_y + radius * 0.90 * Math.sin(minute_angle)
        );
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.19 * Math.cos(minute_angle),
            center_y + radius * 0.19 * Math.sin(minute_angle),
            7
        );
        dc.fillCircle(
            center_x + radius * 0.91 * Math.cos(minute_angle),
            center_y + radius * 0.91 * Math.sin(minute_angle),
            7
        );

        // draw the minute hand
        dc.setColor((Graphics.COLOR_DK_RED), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(
            center_x , 
            center_y ,
            center_x + radius * 0.90 * Math.cos(minute_angle),
            center_y + radius * 0.90 * Math.sin(minute_angle)
        );  
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(10);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(minute_angle), 
            center_y + radius * 0.20 * Math.sin(minute_angle), 
            center_x + radius * 0.90 * Math.cos(minute_angle),
            center_y + radius * 0.90 * Math.sin(minute_angle)
        );
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.19 * Math.cos(minute_angle),
            center_y + radius * 0.19 * Math.sin(minute_angle),
            5
        );
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x + radius * 0.91 * Math.cos(minute_angle),
            center_y + radius * 0.91 * Math.sin(minute_angle),
            5
        );
        dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawLine(
            center_x + radius * 0.20 * Math.cos(minute_angle), 
            center_y + radius * 0.20 * Math.sin(minute_angle), 
            center_x + radius * 0.90 * Math.cos(minute_angle),
            center_y + radius * 0.90 * Math.sin(minute_angle)
        );

        //center
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x ,
            center_y ,
            10
        );
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x ,
            center_y ,
            7
        );
        dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x ,
            center_y ,
            8
        );
        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            center_x ,
            center_y ,
            4
        );
    }

    function isBasicTheme(theme) {
        if (theme == 1) {
            return true;
        }
        return false;
    }

    function isWithinTimeRange(hours, minutes, nightMode) as Boolean {
        // Check if the time is within the range and in night mode
        var hoursNightModeBegin = Properties.getValue("NightModeBegin"); 
        //var hoursNightModeBegin = 22; 
        var hoursNightModeEnd = Properties.getValue("NightModeEnd"); 
        //var hoursNightModeEnd = 7; 
        if (nightMode) {
            if ((hours >= hoursNightModeBegin) || (hours < hoursNightModeEnd)) {
                return true;
            } 
            return false;
        } 
        return false;
    }

    //
    // NOUVELLE FONCTION drawHourMarkers REMPLACÉE CI-DESSOUS
    //
    private function drawHourMarkers(dc as Dc) as Void {
        dc.setColor(0xFFD700, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        
        var outerRadius = _radiusMarkers - 5;
        var innerRadius = _radiusMarkers - 20; // Allongé de 15 à 20 (5 pixels de plus)
        
        // Dessiner les traits d'heures
        for (var i = 0; i < 24; i++) {
            var angle = (i * Math.PI * 2) / 24 - Math.PI / 2;
            var cos = Math.cos(angle);
            var sin = Math.sin(angle);
            
            var x1 = _centerX + outerRadius * cos;
            var y1 = _centerY + outerRadius * sin;
            var x2 = _centerX + innerRadius * cos;
            var y2 = _centerY + innerRadius * sin;
            
            dc.drawLine(x1, y1, x2, y2);
            
            // Ajouter 3 points entre ce trait et le suivant
            dc.setColor(0xFFD700, Graphics.COLOR_TRANSPARENT); // Couleur or pour les points
            for (var j = 1; j <= 3; j++) {
                // Calculer l'angle pour chaque point (répartition égale)
                var nextHourAngle = ((i + 1) * Math.PI * 2) / 24 - Math.PI / 2;
                var pointAngle = angle + (nextHourAngle - angle) * j / 4;
                
                var pointCos = Math.cos(pointAngle);
                var pointSin = Math.sin(pointAngle);
                
                // Position des points (plus près du bord extérieur)
                var pointRadius = _radiusMarkers - 8;
                var pointX = _centerX + pointRadius * pointCos;
                var pointY = _centerY + pointRadius * pointSin;
                
                // Dessiner le point
                dc.fillCircle(pointX, pointY, 1);
            }
        }
        
        // Numéros des heures principales
        // Lit le paramètre utilisateur pour déterminer les labels
        //var isInverted = Application.getApp().getProperty("invertDisplay");

        var topLabel = "12";
        var bottomLabel = "6";
        var leftLabel = "9";
        var rightLabel = "3";

        // Dessine les labels en fonction de la condition
        dc.setColor(0xFFD700, Graphics.COLOR_TRANSPARENT);  
        dc.drawText(_centerX, _centerY - _radiusMarkers * 0.92, Graphics.FONT_XTINY, topLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_centerX, _centerY + _radiusMarkers * 0.78, Graphics.FONT_XTINY, bottomLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_centerX - _radiusMarkers * 0.86, _centerY - _radiusMarkers * 0.08, Graphics.FONT_XTINY, leftLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_centerX + _radiusMarkers * 0.86, _centerY - _radiusMarkers * 0.08, Graphics.FONT_XTINY, rightLabel, Graphics.TEXT_JUSTIFY_CENTER);

    }

    // NOUVELLE FONCTION : pour dessiner background
     private function drawConcentricBackground(dc as Dc) as Void {
        // Couleurs du dégradé du plus foncé au plus clair
        var colors = [
            0x000510, // Centre: Bleu très très sombre
            0x000A18,
            0x001020,
            0x001528,
            0x001A30,
            0x002038,
            0x002540,
            0x003048,
            0x003550,
            0x004060  // Extérieur: Bleu nuit plus clair
        ];
        var maxRadius = _radius + 20;
        var numRings = colors.size();
        
        // Dessiner les cercles concentriques du plus grand au plus petit
        for (var i = numRings - 1; i >= 0; i--) {
            var ringRadius = maxRadius * (i + 1) / numRings;
            dc.setColor(colors[i], Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_centerX, _centerY, ringRadius);
        }
    }

    private function drawStarField(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Vous pouvez ajuster le nombre d'étoiles ici
        var numStars = 200;
        var width = dc.getWidth();
        var height = dc.getHeight();

        // Utilise une graine (seed) constante pour que le champ d'étoiles soit
        // identique à chaque appel. C'est un simple générateur pseudo-aléatoire.
        var seed = 1;

        for (var i = 0; i < numStars; i++) {
            // Génère une coordonnée X pseudo-aléatoire
            seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF;
            var x = seed % width;

            // Génère une coordonnée Y pseudo-aléatoire
            seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF;
            var y = seed % height;

            // Fait varier la taille des étoiles pour un effet plus naturel
            // 30% des étoiles seront un peu plus grandes.
            seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF;
            var size = (seed % 10 > 7) ? 2 : 1;

            dc.fillCircle(x, y, size);
        }
    }




    //NOUVELLE FONCTION pour dessiner le mois en suivant une courbe
    private function drawCurvedMonth(dc as Dc) as Void {
        // NOUVEAU : Tableau des noms des mois en anglais
        var monthNames = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

        // On récupère les informations de date avec le mois en tant que NUMÉRO (1-12)
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var monthNumber = today.month;

        // On sélectionne le nom du mois en anglais dans notre tableau
        // (on soustrait 1 car les tableaux commencent à l'index 0)
        var monthString = monthNames[monthNumber - 1];

        // Le reste de la fonction est inchangé et dessinera le mot anglais
        var font = Graphics.FONT_XTINY;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var DateColor = Properties.getValue("DateColor") ; 
        dc.setColor(DateColor, Graphics.COLOR_TRANSPARENT);

        var textRadius = _radiusMarkers - 28;
        var anglePerChar = 0.12; 
        var totalAngle = monthString.length() * anglePerChar;
        var centerAngle = (2.0 / 24.0) * Math.PI * 2 - Math.PI / 2;
        var startAngle = centerAngle - (totalAngle / 2.0);

        for (var i = 0; i < monthString.length(); i++) {
            var charAngle = startAngle + (i * anglePerChar);
            var char = monthString.substring(i, i + 1);

            var x = _centerX + textRadius * Math.cos(charAngle);
            var y = _centerY + textRadius * Math.sin(charAngle);

            dc.drawText(x, y, font, char, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // NOUVELLE FONCTION pour dessiner la date et l'icône de batterie en courbe
    private function drawSystemInfo(dc as Dc) as Void {
        // --- 1. Dessin de la date en courbe avec espacement ---
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dayString = today.day.format("%02d");

        var font = Graphics.FONT_XTINY;
        var DateColor = Properties.getValue("DateColor");
        dc.setColor(DateColor, Graphics.COLOR_TRANSPARENT);

        var textRadius = _radiusMarkers - 28;
        
        // Espacement de base entre les centres des caractères
        var baseSpacing = 0.12; 
        // NOUVEAU : Espace supplémentaire à ajouter
        var extraSpaceAngle = 0.02; // Ajustez cette valeur pour plus/moins d'espace

        // L'angle de la position centrale (4h30) reste notre référence
        var centerAngle = (3.5 / 24.0) * Math.PI * 2 - Math.PI / 2;
        
        // L'écart total entre les centres des deux chiffres sera la somme des espacements
        var totalSpacing = baseSpacing + extraSpaceAngle;

        // Calculer l'angle pour chaque chiffre en se basant sur le centre
        var tensAngle = centerAngle - (totalSpacing / 2.0);
        var unitsAngle = centerAngle + (totalSpacing / 2.0);

        // Dessiner le premier chiffre (dizaines)
        var tensChar = dayString.substring(0, 1);
        var x1 = _centerX + textRadius * Math.cos(tensAngle);
        var y1 = _centerY + textRadius * Math.sin(tensAngle);
        dc.drawText(x1, y1, font, tensChar, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Dessiner le second chiffre (unités)
        var unitsChar = dayString.substring(1, 2);
        var x2 = _centerX + textRadius * Math.cos(unitsAngle);
        var y2 = _centerY + textRadius * Math.sin(unitsAngle);
        dc.drawText(x2, y2, font, unitsChar, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

    }

    // NOUVELLE FONCTION : pour dessiner la phase de la Lune  
     private function drawMoonPhase(dc as Dc) as Void {
        //var settings = System.getDeviceSettings();
        //_hasNotifications = settings.notificationCount > 0;
        
        //if (_hasNotifications) {
            // Position de la lune
            var moonX = _centerX + _centerX / 2;
            var moonY = _centerY + _centerY / 2;  
            var moonRadius = 28; 
   
            // Calcul de la phase de la Lune (formule plus fiable)
            var today = Time.now();
            var dateInfo = Gregorian.info(today, Time.FORMAT_SHORT);
            
            // Calcul du jour julien
            var year = dateInfo.year;
            var month = dateInfo.month;
            var day = dateInfo.day;
            
            var ye = year;
            var m = month;
            if (month <= 2) {
                ye = ye - 1;
                m = m + 12;
            }
            var a = Math.floor(ye / 100);
            var b = 2 - a + Math.floor(a / 4);
            var julianDay = Math.floor(365.25 * (ye + 4716)) + Math.floor(30.6001 * (m + 1)) + day + b - 1524.5;
            
            // Phase de la lune (0 = Nouvelle Lune, 1 = Pleine Lune)
            var lunarDaysSinceNewMoon = (julianDay - 2451550.1).toFloat(); // Jour julien de la Nouvelle Lune de janvier 2000
            var phase = lunarDaysSinceNewMoon / 29.530588853;
            phase = phase - Math.floor(phase);


            // Dessiner l'ombre de la lune
            var shadowColor = 0x001133;
            
            // Dessiner un cercle blanc pour la lune
            dc.setColor(shadowColor, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(moonX, moonY, moonRadius);
            
           
            // Calculer le décalage de l'ombre pour un effet de croissant
            var shadowOffset = Math.cos(phase * Math.PI * 2);
            
            // L'ombre est plus foncée au milieu du cycle (croissant/décroissant)
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            
            // Dessiner la partie ombragée
            for (var y = -moonRadius; y <= moonRadius; y++) {
                var x = Math.sqrt(moonRadius * moonRadius - y * y);
                var xOffset = x * shadowOffset;
                
                // Si la phase est croissante
                if (phase <= 0.5) {
                    dc.drawLine(moonX + xOffset.toNumber(), moonY + y, moonX + x.toNumber(), moonY + y);
                } 
                // Si la phase est décroissante
                else {
                    dc.drawLine(moonX - x.toNumber(), moonY + y, moonX - xOffset.toNumber(), moonY + y);
                }
            }
            dc.setColor(0xFF8C00, Graphics.COLOR_TRANSPARENT); // Orange
            dc.setPenWidth(5);
            //dc.drawCircle(moonX, moonY, moonRadius);
        //}
    }

}