import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

class DarkSideMoonWatchView extends WatchUi.WatchFace {
    // 2 pi
    var TWO_PI = Math.PI * 2;
    //angle adjust for time hands
    var ANGLE_ADJUST = Math.PI / 2.0;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get the current time and format it correctly
        //var timeFormat = "$1$:$2$";
        //var clockTime = System.getClockTime();
        //var hours = clockTime.hour;


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
        //System.println(today.year);
        //System.println(today.month);
        //System.println(today.day);
        var moonNumber = getMoonPhase(today.year, today.month, today.day); 
        //System.println(moonNumber);

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

/*
        if ((System.getSystemStats().battery) < 20 && (System.getSystemStats().battery > 10) ) {       
            if (!System.getDeviceSettings().is24Hour) {
                if (hours > 12) {
                    hours = hours - 12;
                }
            } else {
                //if (getApp().getProperty("UseMilitaryFormat")) {
                    timeFormat = "$1$$2$";
                    hours = hours.format("%02d");
                //}
            }
            var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

            // Update the view
            var view = View.findDrawableById("TimeLabel") as Text;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, timeString, Graphics.TEXT_JUSTIFY_CENTER);

            //view.setText(timeString);
        }
*/
        var battery = System.getSystemStats().battery;

        if (battery >=20 ) {  

            if (!notificationExist && phoneConnected)  {    

                //Red Moon
                var RedMoon = WatchUi.loadResource(Rez.Drawables.redmoon) ;
                dc.drawBitmap(center_x, center_y, RedMoon) ;

                //Moon phase
                showMoonPhase(moonNumber, dc, center_x + center_x / 3 , center_y + center_y / 3);
                
                /*
                if (moonNumber == 0) {
                    var newMoon = WatchUi.loadResource(Rez.Drawables.newMoon) ;
                    dc.drawBitmap(center_x, center_y, newMoon) ;
                }

                if (moonNumber == 1) {
                    var waxingCrescent = WatchUi.loadResource(Rez.Drawables.waxingCrescent) ;
                    dc.drawBitmap(center_x, center_y, waxingCrescent) ;
                }

                if (moonNumber == 2) {
                    var firstQuarter = WatchUi.loadResource(Rez.Drawables.firstQuarter) ;
                    dc.drawBitmap(center_x, center_y, firstQuarter) ;
                }

                if (moonNumber == 3) {
                    var waxingGibbous = WatchUi.loadResource(Rez.Drawables.waxingGibbous) ;
                    dc.drawBitmap(center_x, center_y, waxingGibbous) ;
                }

                if (moonNumber == 4) {
                    var fullMoon = WatchUi.loadResource(Rez.Drawables.fullMoon) ;
                    dc.drawBitmap(center_x, center_y, fullMoon) ;
                }


                if (moonNumber == 5) {
                    var waningGibbous = WatchUi.loadResource(Rez.Drawables.waningGibbous) ;
                    dc.drawBitmap(center_x, center_y, waningGibbous) ;
                }

                if (moonNumber == 6) {
                    var thirdQuarter = WatchUi.loadResource(Rez.Drawables.thirdQuarter) ;
                    dc.drawBitmap(center_x, center_y, thirdQuarter) ;
                }

                if (moonNumber == 7) {
                    var waningCrescent = WatchUi.loadResource(Rez.Drawables.waningCrescent) ;
                    dc.drawBitmap(center_x, center_y, waningCrescent) ;
                }
                */

                //Digits
                /*
                for (var i = 0; i < 24; i++) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);  
                    dc.setPenWidth(2);
                    dc.drawLine(
                        (center_x + radius * 0.9 * Math.cos(i * 15 * TWO_PI / 360)), 
                        (center_y + radius * 0.9 * Math.sin(i * 15 * TWO_PI / 360)),
                        (center_x + radius * Math.cos(i * 15 * TWO_PI / 360)),
                        (center_y + radius * Math.sin(i * 15 * TWO_PI / 360))
                    );
                }

                for (var i = 0; i < 24; i++) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);  
                    dc.setPenWidth(2);
                    dc.drawLine(
                        (center_x + radius * 0.8 * Math.cos((i * 15 + 15/2) * TWO_PI / 360)), 
                        (center_y + radius * 0.8 * Math.sin((i * 15 + 15/2) * TWO_PI / 360)),
                        (center_x + radius * Math.cos((i * 15 + 15/2) * TWO_PI / 360)),
                        (center_y + radius * Math.sin((i * 15 + 15/2) * TWO_PI / 360))
                    );
                }
                */


                //Top Arc
                dc.setPenWidth(3);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawArc(center_x, center_y, radius * 0.74, Graphics.ARC_COUNTER_CLOCKWISE, 60,120);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawArc(center_x, center_y, radius * 0.77, Graphics.ARC_COUNTER_CLOCKWISE, 70,110);
                    
                //Left Arc
                dc.setPenWidth(3);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
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
                dc.drawText(center_x, center_y - radius , Graphics.FONT_SYSTEM_MEDIUM, "12", Graphics.TEXT_JUSTIFY_CENTER);
                dc.drawText(center_x, center_y + radius * 0.75, Graphics.FONT_SYSTEM_MEDIUM, "6", Graphics.TEXT_JUSTIFY_CENTER);
                dc.drawText(center_x - radius * 0.93, center_y - radius * 0.12, Graphics.FONT_SYSTEM_MEDIUM, "9", Graphics.TEXT_JUSTIFY_CENTER);
                dc.drawText(center_x + radius * 0.93, center_y - radius * 0.12 , Graphics.FONT_SYSTEM_MEDIUM, "3", Graphics.TEXT_JUSTIFY_CENTER);

        
                //Second Right Arc ; seconds
                var secArc = sec / 60.0 * 60.0;
                var drawSecArc = -30 + secArc; 
                dc.setPenWidth(5);
                dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_RED);
                dc.drawArc(center_x,center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, drawSecArc, 30);

                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
                dc.drawText(center_x + radius * 0.65, center_y , Graphics.FONT_SYSTEM_XTINY,  sec +"s", Graphics.TEXT_JUSTIFY_CENTER);
            
                
                //Second Left Arc : battery
                var batteryPercent = System.getSystemStats().battery / 100.0 * 60.0;
                var drawBattery = 150 + batteryPercent;
                dc.setPenWidth(5);
                dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_RED);
                dc.drawArc(center_x, center_y, radius * 0.8, Graphics.ARC_COUNTER_CLOCKWISE, drawBattery,210);
        
                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
                dc.drawText(center_x - radius * 0.65, center_y , Graphics.FONT_SYSTEM_XTINY,  System.getSystemStats().battery.toNumber() +"%", Graphics.TEXT_JUSTIFY_CENTER);

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
                dc.setColor((Graphics.COLOR_RED), Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(4);
                dc.drawLine(
                    center_x + radius * 0.20 * Math.cos(minute_angle), 
                    center_y + radius * 0.20 * Math.sin(minute_angle),
                    center_x + radius * 0.90 * Math.cos(minute_angle),
                    center_y + radius * 0.90 * Math.sin(minute_angle)
                );
            }
            
            if (notificationExist && phoneConnected)  {  
                var notification = WatchUi.loadResource(Rez.Drawables.notification) ;
                dc.drawBitmap(center_x - radius, center_y -radius, notification) ;

                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, hour.format("%02d")+":"+min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
            }  

            if (!phoneConnected)  {  
                var connected = WatchUi.loadResource(Rez.Drawables.connected) ;
                dc.drawBitmap(center_x - radius, center_y -radius, connected) ;

                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, hour.format("%02d")+":"+min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
            }  


        }

        if ((battery < 20) && (battery > 10) ) {       
            var blackhole = WatchUi.loadResource(Rez.Drawables.blackhole) ;
            dc.drawBitmap(center_x - radius, center_y -radius, blackhole) ;

            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, hour.format("%02d")+":"+min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
        }

        if (battery <= 10) {       
            var creature = WatchUi.loadResource(Rez.Drawables.creature) ;
            dc.drawBitmap(center_x - radius, center_y -radius, creature) ;

            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(center_x, center_y , Graphics.FONT_SYSTEM_MEDIUM, hour.format("%02d")+":"+min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
        }
           
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
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
