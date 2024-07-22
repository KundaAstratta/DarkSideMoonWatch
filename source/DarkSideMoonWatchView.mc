import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

class DarkSideMoonWatchView extends WatchUi.WatchFace {
    // Ajoutez ces variables pour les étoiles
    var starX = [];
    var starY = [];
    var starSpeed = [];
    var starCount = 20; // Nombre d'étoiles
    var screenWidth;
    var screenHeight;

    // 2 pi
    var TWO_PI = Math.PI * 2;
    //angle adjust for time hands
    var ANGLE_ADJUST = Math.PI / 2.0;
    //is in sleep mode
    var isInSleepMode = false;
    //theme
    var theme = 1;

    function initialize() {
        WatchFace.initialize();
        // Initialisation des étoiles
        screenWidth = 320;
        screenHeight = 320;
        initializeStars();
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

    // Initialiser les étoiles avec des positions aléatoires
    function initializeStars() {
        starX = new [starCount];
        starY = new [starCount];
        starSpeed = new [starCount];
        for (var i = 0; i < starCount; i++) {
            starX[i] = Math.floor(getRandom() * screenWidth);
            starY[i] = Math.floor(getRandom() * screenHeight);
            starSpeed[i] = 0.2;//getRandom() * 0.02 + 0.01; // Vitesse aléatoire
        }
    }

    function updateStars() {
        for (var i = 0; i < starCount; i++) {
            starX[i] -= starSpeed[i]; // Déplacer l'étoile vers la gauche
            if (starX[i] < 0) {
                starX[i] = screenWidth; // Réinitialiser la position de l'étoile à droite
                starY[i] = Math.floor(getRandom() * screenHeight); // Nouvelle position verticale aléatoire
                starSpeed[i] = 0.2;//getRandom() * 0.02 + 0.01; // Nouvelle vitesse aléatoire
            }
        }
    }

    function drawStars(dc) {
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < starCount; i++) {
            dc.fillCircle(starX[i], starY[i], 3); // Dessiner un cercle blanc de rayon 2
        }
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        isInSleepMode = false;
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
        var moonNumber = getMoonPhase(today.year, ((today.month)-1), today.day); 

        
        var notificationCount = System.getDeviceSettings().notificationCount;
        var notificationExist = false;
        if (notificationCount == 0) {
            notificationExist = false;
        } else {
            notificationExist = true;
        }

        var phoneConnected = System.getDeviceSettings().phoneConnected;

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        var battery = System.getSystemStats().battery;

        theme = Properties.getValue("Theme");


        //TEST
        //isInSleepMode =  true;
        //TEST


        var isNightMode = Properties.getValue("NightMode"); 

        //Main Here

        //Noght mode ?
        if (isWithinTimeRange(hour,min, isNightMode)) {
            //BasicTheme
            if (!isAdventureTheme(theme)) {
                drawHourandMinutesHandNight(dc,center_x,center_y,radius,hour_angle,minute_angle);   
            } 
            //Adventure Theme
            if (isAdventureTheme(theme)) {
                drawHourandMinutesHandAdventureNight(dc,center_x,center_y,radius,hour_angle,minute_angle);
            }         
        } 
        
        //To calculate if is normal mode or night mode
        if (!isWithinTimeRange(hour,min,isNightMode)) {

            //Sleep Mode ?
            if (isInSleepMode) {
                //Basic Theme
                if (!isAdventureTheme(theme)) {
                drawHourandMinutesHand(dc,center_x,center_y,radius,hour_angle,minute_angle);
                }
                //Adventure THeme
                if (isAdventureTheme(theme)) {
                    drawHourandMinutesHandAdventure(dc,center_x,center_y,radius,hour_angle,minute_angle);
                }

            }
            if (!isInSleepMode) {

                if (battery >=20) {  

                    if (!notificationExist && phoneConnected)  {   
                        normalLevelBatteryAndNotificationNotExistAndPhoneConnected(dc,moonNumber, center_x,center_y,radius,hour_angle,minute_angle,today,sec);
                        //draw seconde hand only for adventure theme
                        if (isAdventureTheme(theme)) {
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
                                dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
                                dc.setPenWidth(3);
                                dc.drawLine(
                                    center_x , 
                                    center_y , 
                                    center_x + radius * 0.95 * Math.cos(seconde_angle),
                                    center_y + radius * 0.95 * Math.sin(seconde_angle)
                                );
                            }
                        }
                    }
                    
                    if (notificationExist && phoneConnected)  {  
                        normalLevelBatteryAndNotificationExistAndPhoneConnected(dc, center_x,center_y,radius,hour, min);
                    }  

                    if (!phoneConnected)  {  
                        normalLevelBatteryAndPhoneNotConnected(dc, center_x,center_y,radius,hour, min);
                    }  

                }

                if ((battery < 20) && (battery > 10) ) {  
                ifBatteryBetweenTenAndTwenty(dc,battery, center_x,center_y, radius, hour, min);
                }

                if (battery <= 10) {     
                    ifBatteryLessThanTen(dc,battery, center_x,center_y, radius, hour, min);
                }

            }

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
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isInSleepMode = true;
    }

    function normalLevelBatteryAndNotificationNotExistAndPhoneConnected(dc,moonNumber,center_x,center_y,radius,hour_angle,minute_angle, today, sec) {
       

        //var isStarsSky = Properties.getValue("StarsSky"); 
        var isStarsSky = false; 


        if (isStarsSky) {
            // Mise à jour des positions des étoiles
            updateStars();

            // Dessiner les étoiles
            drawStars(dc);
        }
        //Background Moon
        var RedMoon = WatchUi.loadResource(Rez.Drawables.redmoon) ;
        dc.drawBitmap(center_x, center_y, RedMoon) ;


        //Moon phase
        showMoonPhase(moonNumber, dc, center_x + center_x / 3 , center_y + center_y / 3);

        //Top Arc
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(center_x, center_y, radius * 0.74, Graphics.ARC_COUNTER_CLOCKWISE, 60,120);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(center_x, center_y, radius * 0.77, Graphics.ARC_COUNTER_CLOCKWISE, 70,110);
            
        //Left Arc
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        if (isAdventureTheme(theme)) {
            dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT );
        }
        dc.drawArc(center_x, center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, 150,210);

        //Right Arc
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(center_x, center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, -30,30);

    
        //Bottom Arc
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(center_x, center_y, radius * 0.74, Graphics.ARC_COUNTER_CLOCKWISE, 240,300);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(center_x, center_y, radius * 0.77, Graphics.ARC_COUNTER_CLOCKWISE, 250,290);
        
        //Numbers
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);         
        if (isAdventureTheme(theme)) {
            dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT );
        } 
        dc.drawText(center_x, center_y - radius , Graphics.FONT_SYSTEM_MEDIUM, "12", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(center_x, center_y + radius * 0.75, Graphics.FONT_SYSTEM_MEDIUM, "6", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(center_x - radius * 0.93, center_y - radius * 0.12, Graphics.FONT_SYSTEM_MEDIUM, "9", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(center_x + radius * 0.93, center_y - radius * 0.12 , Graphics.FONT_SYSTEM_MEDIUM, "3", Graphics.TEXT_JUSTIFY_CENTER);

        //Date
        var isShowDate = Properties.getValue("ShowDate"); 
        var DateColor = Properties.getValue("DateColor") ; 

        if (isShowDate) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);  
            dc.setColor(DateColor, Graphics.COLOR_TRANSPARENT);  
            dc.drawText(center_x + radius * 0.6, center_y + radius * 0.50 , Graphics.FONT_SYSTEM_SMALL, today.day.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);   
        }     

        //Second Right Arc ; seconds
        var secArc = sec / 60.0 * 60.0;
        var drawSecArc = -30 + secArc; 
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_RED);
        if (isAdventureTheme(theme)) {
            dc.setColor(0xAA5500, 0xAA5500);
        }


        dc.drawArc(center_x,center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, drawSecArc, 30);

        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
        dc.drawText(center_x + radius * 0.65, center_y , Graphics.FONT_SYSTEM_XTINY,  sec +"s", Graphics.TEXT_JUSTIFY_CENTER);
    
        
        //Second Left Arc : battery
        var batteryPercent = System.getSystemStats().battery / 100.0 * 60.0;
        var drawBattery = 150 + batteryPercent;
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_RED);
        if (isAdventureTheme(theme)) {
            dc.setColor(0x999999,0x999999);
        }
        dc.drawArc(center_x, center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, drawBattery,210);

        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
        dc.drawText(center_x - radius * 0.65, center_y , Graphics.FONT_SYSTEM_XTINY,  System.getSystemStats().battery.toNumber() +"%", Graphics.TEXT_JUSTIFY_CENTER);

        //Basic Theme
        if (!isAdventureTheme(theme)) {
            drawHourandMinutesHand(dc,center_x,center_y,radius,hour_angle,minute_angle);
        }   
        //Adventure Theme
        if (isAdventureTheme(theme)) {
            drawHourandMinutesHandAdventure(dc,center_x,center_y,radius,hour_angle,minute_angle);
        }   
    }

    function normalLevelBatteryAndNotificationExistAndPhoneConnected(dc, center_x,center_y,radius,hour, min) {
        var notification = WatchUi.loadResource(Rez.Drawables.notification) ;
        dc.drawBitmap(center_x - radius, center_y -radius, notification) ;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (isAdventureTheme(theme)) {
            dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, hour.format("%02d")+":"+min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
    }

    function normalLevelBatteryAndPhoneNotConnected(dc, center_x,center_y,radius,hour, min) {
        var connected = WatchUi.loadResource(Rez.Drawables.connected) ;
        dc.drawBitmap(center_x - radius, center_y -radius, connected) ;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (isAdventureTheme(theme)) {
            dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, hour.format("%02d")+":"+min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
    }


    function ifBatteryBetweenTenAndTwenty(dc, battery, center_x, center_y, radius,hour,min) {
        var blackhole = WatchUi.loadResource(Rez.Drawables.blackhole) ;
        dc.drawBitmap(center_x - radius, center_y - radius, blackhole) ;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (isAdventureTheme(theme)) {
            dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, hour.format("%02d")+":"+min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
    }

    function ifBatteryLessThanTen(dc,battery, center_x,center_y, radius, hour, min) {
        var creature = WatchUi.loadResource(Rez.Drawables.creature) ;
        dc.drawBitmap(center_x - radius, center_y -radius, creature) ;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (isAdventureTheme(theme)) {
            dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
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
        if (isAdventureTheme(theme)) {
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
        if (isAdventureTheme(theme)) {
            dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
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
        dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
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
        dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
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
        dc.setColor(0xAA5500,Graphics.COLOR_TRANSPARENT);
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

    function isAdventureTheme(theme) {
        if (theme == 2) {
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

    function showMoonPhase(moonNumber,dc,x,y) {
        if (moonNumber == 0) {
            var newMoon = WatchUi.loadResource(Rez.Drawables.newMoon) ;
            dc.drawBitmap(x, y, newMoon) ;
        }

        if (moonNumber == 1) {
            var waxingCrescent = WatchUi.loadResource(Rez.Drawables.waxingCrescent) ;
            dc.drawBitmap(x, y, waxingCrescent) ;
        }

        if (moonNumber == 2) {
            var firstQuarter = WatchUi.loadResource(Rez.Drawables.firstQuarter) ;
            dc.drawBitmap(x, y, firstQuarter) ;
        }

        if (moonNumber == 3) {
            var waxingGibbous = WatchUi.loadResource(Rez.Drawables.waxingGibbous) ;
            dc.drawBitmap(x, y, waxingGibbous) ;
        }

        if (moonNumber == 4) {
            var fullMoon = WatchUi.loadResource(Rez.Drawables.fullMoon) ;
            dc.drawBitmap(x, y, fullMoon) ;
        }

        if (moonNumber == 5) {
            var waningGibbous = WatchUi.loadResource(Rez.Drawables.waningGibbous) ;
            dc.drawBitmap(x, y, waningGibbous) ;
        }

        if (moonNumber == 6) {
            var thirdQuarter = WatchUi.loadResource(Rez.Drawables.thirdQuarter) ;
            dc.drawBitmap(x, y, thirdQuarter) ;
        }

        if (moonNumber == 7) {
            var waningCrescent = WatchUi.loadResource(Rez.Drawables.waningCrescent) ;
            dc.drawBitmap(x, y, waningCrescent) ;
        }

    }


    function getMoonPhase(year, month, day) {

      var c=0;
      var e=0;
      var jd=0;
      var b=0;

      if (month < 3) {
        year--;
        month += 12;
      }

      ++month; 

      c = 365.25 * year;

      e = 30.6 * month;

      jd = c + e + day - 694039.09; 

      jd /= 29.5305882; 

      b = (jd).toNumber(); 

      jd -= b; 

      b = Math.round(jd * 8); 

      if (b >= 8) {
        b = 0; 
      }
     
      return (b).toNumber();
    }

     /*
     0 => New Moon
     1 => Waxing Crescent Moon
     2 => Quarter Moon
     3 => Waxing Gibbous Moon
     4 => Full Moon
     5 => Waning Gibbous Moon
     6 => Last Quarter Moon
     7 => Waning Crescent Moon
     */


}
