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
                    drawHourandMinutesHand(dc,center_x,center_y,radius,hour_angle,minute_angle);
                }
                //An other theme 
                if (!isBasicTheme(theme)) {
                    drawHourandMinutesHandAdventure(dc,center_x,center_y,radius,hour_angle,minute_angle);
                    if (theme == 4) {
                        drawHourandMinutesHandAdventureNight(dc,center_x,center_y,radius,hour_angle,minute_angle);
                    }
                }

            }
            // Day mode - Begin
            if (!isInSleepMode) {

                if (battery >=20) {  

                    if (!notificationExist && phoneConnected)  {   
                        normalWatchFace(dc,moonNumber, center_x,center_y,radius,hour_angle,minute_angle,today,sec);
                    }
                    
                    if (notificationExist && phoneConnected)  {  
                        if (pictureNotification) { 
                            normalLevelBatteryAndNotificationExistAndPhoneConnected(dc, center_x,center_y,radius,hour, min);
                        }
                        if (!pictureNotification) {
                            normalWatchFace(dc,moonNumber, center_x,center_y,radius,hour_angle,minute_angle,today,sec);
                            iconNotification(dc, center_x,center_y,radius);
                        }
                    }  

                    if (!phoneConnected)  {  
                        if (picturePhoneNotConnected) {
                            normalLevelBatteryAndPhoneNotConnected(dc, center_x,center_y,radius,hour, min);
                        }
                        if (!picturePhoneNotConnected) {
                            normalWatchFace(dc,moonNumber, center_x,center_y,radius,hour_angle,minute_angle,today,sec);
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
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isInSleepMode = true;
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

    function normalWatchFace(dc,moonNumber,center_x,center_y,radius,hour_angle,minute_angle, today, sec) {
        
        var skystarsbackground = Properties.getValue("SkyStars");
        if (skystarsbackground) {
            // Background night/blue
            dc.setColor(Graphics.COLOR_TRANSPARENT, 0x000040); // Bleu nuit foncé
            dc.clear();

            // 2. Draw Stars with random sizes
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT); // Étoiles blanches
            var screenWidth = dc.getWidth();
            var screenHeight = dc.getHeight();
            var numStars = 50; // Nombre d'étoiles, ajustez selon vos préférences

            for (var i = 0; i < numStars; i += 1) {
                var starX = Math.rand() % screenWidth;  // Position X aléatoire
                var starY = Math.rand() % screenHeight; // Position Y aléatoire
                
                // Génère 0 ou 1, puis ajoute 1 pour obtenir 1 ou 2 ou 3.
                var starRadius = (Math.rand() % 3) + 1; 
                // dc.fillCircle(starX, starY, 1); // Ancienne ligne avec taille fixe
                dc.fillCircle(starX, starY, starRadius); // Nouvelle ligne avec taille aléatoire
            }
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
        var isShowMinuteMarkers = Properties.getValue("ShowMinuteMarkers"); 
        if (isShowMinuteMarkers) {
            drawHourMarkers(dc, center_x, center_y, radius);
        }

        //Moon phase
        showMoonPhase(moonNumber, dc, center_x + center_x / 3 , center_y + center_y / 3);

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

        // Numbers (avec contour noir pour 3 et 6)
        var outlineWidth = 1; // Épaisseur du contour noir
        var numbersWithOutline = [3, 6];

        //Numbers
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);         
        if (!isBasicTheme(theme)) {
            if (theme == 2) {
                dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 3) {
                dc.setColor(0x7FFF00, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 4) {
                dc.setColor(0xFF0000,Graphics.COLOR_TRANSPARENT);
            }
        } 

        for (var i = 0; i < 12; i++) {
            var hourText = (i == 0) ? "12" : i.toString(); // Afficher "12" pour l'heure 0
            var angle = ((i % 12) / 12.0) * TWO_PI - ANGLE_ADJUST;
            var textX = 0; 
            var textY = 0;

            if (i == 0) { // 12 en haut
                textX = center_x;
                textY = center_y - radius;
            } else if (i == 3) { // 3 à droite
                textX = center_x + radius * 0.93;
                textY = center_y - radius * 0.13;
            } else if (i == 6) { // 6 en bas
                textX = center_x;
                textY = center_y + radius * 0.75;
            } else if (i == 9) { // 9 à gauche
                textX = center_x - radius * 0.93;
                textY = center_y - radius * 0.13;
            }

            // Dessiner le contour noir si l'heure est dans numbersWithOutline
            if (numbersWithOutline.indexOf(i) != -1) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.drawText(textX + outlineWidth, textY - outlineWidth, Graphics.FONT_SYSTEM_MEDIUM, hourText, Graphics.TEXT_JUSTIFY_CENTER);
                dc.drawText(textX - outlineWidth, textY + outlineWidth, Graphics.FONT_SYSTEM_MEDIUM, hourText, Graphics.TEXT_JUSTIFY_CENTER);
                dc.drawText(textX + outlineWidth, textY + outlineWidth, Graphics.FONT_SYSTEM_MEDIUM, hourText, Graphics.TEXT_JUSTIFY_CENTER);
                dc.drawText(textX - outlineWidth, textY - outlineWidth, Graphics.FONT_SYSTEM_MEDIUM, hourText, Graphics.TEXT_JUSTIFY_CENTER);
            }

            // Dessiner le texte de l'heure par-dessus le contour
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            if (!isBasicTheme(theme)) {
                if (theme == 2) {
                    dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
                }
                if (theme == 3) {
                    dc.setColor(0x7FFF00, Graphics.COLOR_TRANSPARENT);
                }
                if (theme == 4) {
                    dc.setColor(0xFF0000,Graphics.COLOR_TRANSPARENT);
                }    
            }
            dc.drawText(textX, textY, Graphics.FONT_SYSTEM_MEDIUM, hourText, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
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

    // Nouvelle fonction pour dessiner les tirets
    function drawHourMarkers(dc, center_x, center_y, radius) {
        var markerHours = [1, 2, 4, 5, 7, 8, 10, 11]; // Heures avec tirets principaux
        var mainMarkerLength = 0.10 * radius; // Longueur des tirets principaux
        var smallMarkerLength = 0.025 * radius; // Longueur des petits tirets
        var markerOffset = 0.95 * radius; // Distance du centre 
        var mainMarkers = Properties.getValue("MainMarkers");

        // Dessiner les tirets pour toutes les heures et les petits tirets entre eux
        for (var hour = 0; hour < 12; hour++) {
            var angle = ((hour % 12) / 12.0) * TWO_PI - ANGLE_ADJUST;


            // Dessiner le contour noir pour le tiret principal
            if (markerHours.indexOf(hour) != -1) {
                drawMarkerWithOutline(dc, center_x, center_y, markerOffset, angle, mainMarkerLength, 6, 4);
            }

            // Dessiner les contours noirs pour les petits tirets entre les heures
            if (!mainMarkers) {
                for (var j = 1; j < 5; j++) {
                    var smallMarkerAngle = angle + j * (TWO_PI / 60);  // Ajustement de l'incrément pour les petits tirets
                    drawMarkerWithOutline(dc, center_x, center_y, markerOffset, smallMarkerAngle, smallMarkerLength, 6, 4);
                }
            } 

            // Dessiner le tiret principal si l'heure est dans markerHours
            if (markerHours.indexOf(hour) != -1) {
                var startX = center_x + markerOffset * Math.cos(angle);
                var startY = center_y + markerOffset * Math.sin(angle);
                var endX = center_x + (markerOffset - mainMarkerLength) * Math.cos(angle);
                var endY = center_y + (markerOffset - mainMarkerLength) * Math.sin(angle);
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                if (!isBasicTheme(theme)) {
                    if (theme == 2) {
                        dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
                    } 
                    if (theme == 3) {
                        dc.setColor(0x7FFF00, Graphics.COLOR_TRANSPARENT);
                    }
                    if (theme == 4) {
                        dc.setColor(0xFF0000,Graphics.COLOR_TRANSPARENT);
                    }
                }
                dc.setPenWidth(4); // Épaisseur des tiretsf
                dc.drawLine(startX, startY, endX, endY);
            }

            // Dessiner les petits tirets entre les heures
            if (!mainMarkers) {
                for (var j = 1; j < 5; j++) {
                    var smallMarkerAngle = angle + j * (TWO_PI / 60);  // Ajustement de l'incrément pour les petits tirets
                    var smallStartX = center_x + markerOffset * Math.cos(smallMarkerAngle);
                    var smallStartY = center_y + markerOffset * Math.sin(smallMarkerAngle);
                    var smallEndX = center_x + (markerOffset - smallMarkerLength) * Math.cos(smallMarkerAngle);
                    var smallEndY = center_y + (markerOffset - smallMarkerLength) * Math.sin(smallMarkerAngle);

                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    if (!isBasicTheme(theme)) {   
                        dc.setColor(0x999999, Graphics.COLOR_TRANSPARENT);
                    }
                    dc.setPenWidth(4); // Épaisseur des tirets
                    dc.drawLine(smallStartX, smallStartY, smallEndX, smallEndY);
                }
            }
        }
    }

    // Fonction pour dessiner un tiret avec un contour noir
    function drawMarkerWithOutline(dc, centerX, centerY, offset, angle, length, outlineWidth, fillWidth) {
        // Calculer les points de départ et de fin du tiret
        var startX = centerX + offset * Math.cos(angle);
        var startY = centerY + offset * Math.sin(angle);
        var endX = centerX + (offset - length) * Math.cos(angle);
        var endY = centerY + (offset - length) * Math.sin(angle);

        // Dessiner le contour noir
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(outlineWidth);
        dc.drawLine(startX, startY, endX, endY);

        // Dessiner le tiret intérieur coloré
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (!isBasicTheme(theme)) {
            if (theme == 2) {
                dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 3) {
                dc.setColor(0x7FFF00, Graphics.COLOR_TRANSPARENT);
            }
            if (theme == 4) {
                dc.setColor(0xFF0000,Graphics.COLOR_TRANSPARENT);
            }
        }
        dc.setPenWidth(fillWidth);
        dc.drawLine(startX, startY, endX, endY);
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
