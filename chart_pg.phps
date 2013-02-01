<?php

$mysql_hostname = 'localhost';
$mysql_dbname   = 'pwntter';
$mysql_username = 'pwntter';
$mysql_password = 'pwntter';
$mysql_db_engine = 'pgsql'; //'mysql';



?><!DOCTYPE html>
<html>

<head>
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js" type="text/javascript"></script> 
<script src="http://code.highcharts.com/highcharts.js" type="text/javascript"></script>

<!--<script src="jquery.min.js" type="text/javascript"></script>-->
<!--<script src="highcharts.js" type="text/javascript"></script>-->


<style>


.graph
{
	min-width: 500px;
	min-height: 500px;

	max-width:800px;

}

.useragent-icon
{
	width:16px;
	height:16px;
}

.big-user-icon
{
	width:96px;
	height:96px;
}

</style>

</head>
<body>

<h1>PwntterCharts</h1>
<p>a nerdy thing with charts from <a href='http://www.twitter.com/realivansanchez'>@RealIvanSanchez</a></p>

<div><h3>User agents</h3>
<div class='pie graph' id='useragents_container'></div>
</div>


<div><h3>Users</h3>
<div class='pie graph' id='users_container'></div>
</div>


<div><h3>Hours of the day</h3>
<div class='bars graph' id='hours_container'></div>
</div>


<div><h3>Day of week</h3>
<div class='bars graph' id='week_container'></div>
</div>


<div><h3>Day of month</h3>
<div class='bars graph' id='month_container'></div>
</div>


<div><h3>Hours of tweeting by timezone scatterplot</h3>
<div class='scatter graph' id='timezonescatter_container'></div>
</div>


<div><h3>Geolocation scatterplot</h3>
<div class='scatter graph' id='geoscatter_container'></div>
</div>


<?php

/**


DONE: User agents (pie)
DONE: Users (pie)

DONE: Days in month (time)
DONE: Hours in day
DONE: Days in week


TODO: filter by month

DONE: group minor user agents and users

TODO: find a "unknown" icon for missing favicons or the "others" slice


TODO: Read https://dev.twitter.com/terms/display-requirements , and perhaps implement some parts of it. Maybe.

**/

/*
if (!isset($_REQUEST['month']))
	$month = (int) date("i");
else
	$month = (int) $_REQUEST['month'];

if (!isset($_REQUEST['year']))
	$month = (int) date("Y");
else
	$month = (int) $_REQUEST['year'];*/


$pdo = new PDO("$mysql_db_engine:host=$mysql_hostname;dbname=$mysql_dbname", $mysql_username, $mysql_password);


$useragents_data = array();
$users_data = array();
$users_colors = array();
$hours_data = array();
$week_data = array();
$month_data = array();

$useragents_icons = array();
$useragents_urls  = array();
$users_profile_images = array();

$total_tweets = 0;


$r = $pdo->query("select count(s.id) as c, s.url as url, s.name as name, s.icon as icon
	from tweets t, sources s
	where s.id = t.source_id
	group by source_id, s.url, s.name, s.icon
	order by c desc");

while ($row = $r->fetch())
{

	$useragents_data[] = array(            $row[2] , (int)$row[0] );	// Name, Count
// 	$useragents_data[] = array( strip_tags($row[1]), (int)$row[0], $icon );
	$total_tweets += $row[0];

	$useragents_icons[ $row[2] ] = $row[3];
	$useragents_urls[  $row[2] ] = $row[1];
}



$r = $pdo->query("select count(t.screen_name) as c, t.screen_name, u.profile_image_url, u.profile_background_color from tweets t, users u where t.screen_name = u.screen_name group by t.screen_name, u.profile_image_url, u.profile_background_color order by c desc");

while ($row = $r->fetch())
{
	$users_data[] = array( $row[1], (int)$row[0] );
	$users_profile_images[ $row[1] ] = $row[2];
	$users_colors[] = "#" . $row[3];
}

//MySQL
//$r = $pdo->query("select count(hour(created_at)) as c, hour(created_at) as h from tweets group by hour(created_at)");
//Pg
$r = $pdo->query("select count(extract(hour from created_at)) as c, extract(hour from created_at) as h from tweets group by extract(hour from created_at)");

while ($row = $r->fetch())
{
	$hours_data[] = array( (int)$row[1], (int)$row[0] );
}


//MySQL
//$r = $pdo->query("select count(dayofweek(created_at)) as c, dayofweek(created_at) as h from tweets group by dayofweek(created_at)");
//Pg
$r = $pdo->query("select count(extract(dow from created_at)) as c, extract(dow from created_at) as h from tweets group by extract(dow from created_at)");

while ($row = $r->fetch())
{
	$week_data[] = array( (int)$row[1], (int)$row[0] );
}



//MySQL
//$r = $pdo->query("select count(dayofmonth(created_at)) as c, dayofmonth(created_at) as h from tweets group by dayofmonth(created_at)");
//Pg
$r = $pdo->query("select count(extract(day from created_at)) as c, extract(day from created_at) as h from tweets group by extract(day from created_at)");

while ($row = $r->fetch())
{
	$month_data[] = array( (int)$row[1], (int)$row[0] );
}


//MySQL
//$r = $pdo->query("select count(hour(tweets.created_at)) as c, hour(tweets.created_at) as h, utc_offset/3600 as utc from tweets, users
//where tweets.user_id = users.id group by hour(tweets.created_at), utc_offset");
//Pg
$r = $pdo->query("select count(extract(hour from tweets.created_at)) as c, extract(hour from tweets.created_at) as h, utc_offset/3600 as utc from tweets, users
where tweets.user_id = users.id group by extract(hour from tweets.created_at), utc_offset");

while ($row = $r->fetch())
{
	/// Point size is logarithmic in relation to the number of geolocated tweets
	/// Use $total_tweets to make all points bigger or smaller.
	$size = log( ( (int)$row[0] / $total_tweets ) * 2000 , 2) * 2;

	$timezone_scatter_data[] = array( 'x'=> (float)$row[2], 'y'=> (float)$row[1], 'marker'=>array('radius'=> $size ) );

// 	data: [{
// 	    x: 161.2,
// 	    y: 51.6,
// 	    marker: {
// 	        radius: 15,
// 	        fillColor: 'rgb(255, 0, 0)'
// 	    }
// 	}]
}


$r = $pdo->query("select count(concat(geo_lat, geo_long)), geo_lat, geo_long from tweets
where geo_lat is not null and geo_long is not null and (geo_lat != 0 and geo_long != 0)
group by geo_lat, geo_long");

while ($row = $r->fetch())
{
	/// Point size is logarithmic in relation to the number of geolocated tweets
	$size = log( ( (int)$row[0] ) * 2 , 2) * 2;

	$geo_scatter_data[] = array( 'x'=> (float)$row[2], 'y'=> (float)$row[1], 'marker'=>array('radius'=> $size ) );
}





// Strip smallish values off the pie charts.
// By "smallish" I mean less than 1% of total tweets.
$ignored_tweets = 0;
$clean_useragents_data = array();
foreach($useragents_data as $i=>$useragent_point)
{
	if ($useragent_point[1] < ($total_tweets/100) )
	{
		$ignored_tweets += $useragent_point[1];
	}
	else
	{
		$clean_useragents_data[] = $useragent_point;
	}
}

if ($ignored_tweets)	// > 0
{
	$clean_useragents_data[] = array("Others", $ignored_tweets);
}




$ignored_tweets = 0;
$clean_users_data = array();
$clean_users_colors = array();
foreach($users_data as $i=>$users_point)
{
	if ($users_point[1] < ($total_tweets/100/2) )
	{
		$ignored_tweets += $users_point[1];
	}
	else
	{
		$clean_users_data[] = $users_point;
		$clean_users_colors[] = $users_colors[$i];
	}
}

if ($ignored_tweets)	// > 0
{
	$clean_users_data[] = array("Others", $ignored_tweets);
	$clean_users_colors[] = "#808080";
}







$useragents_json = json_encode($clean_useragents_data);
$users_json = json_encode($clean_users_data);
$users_colors_json = json_encode($clean_users_colors);
$hours_json = json_encode($hours_data);
$week_json  = json_encode($week_data);
$month_json = json_encode($month_data);
$timezone_scatter_json = json_encode($timezone_scatter_data);
$geo_scatter_json      = json_encode($geo_scatter_data);

$useragents_icons_json = json_encode($useragents_icons);
$useragents_urls_json  = json_encode($useragents_urls);
$users_profile_json    = json_encode($users_profile_images);



?>
<script type='text/javascript'>


var useragents_icons     = <?php echo $useragents_icons_json; ?>;
var useragents_urls      = <?php echo $useragents_urls_json; ?>;
var users_profile_images = <?php echo $users_profile_json; ?>;

$(function () {


	var pie_label_formatter = function()
	{
	// 	     return '<b>'+ this.point.name +'</b>: '+ this.value +' \\n '+ this.percentage +' %';
	     return '<b>'+ this.point.name +'</b>: '+ Highcharts.numberFormat(this.percentage, 2, '.') +' %';
	}


	var useragent_pie_label_formatter = function()
	{
	// 	     return '<b>'+ this.point.name +'</b>: '+ this.value +' \\n '+ this.percentage +' %';
		var icon = '';
		var link = '';
		var closelink = '';
		if (useragents_icons[this.point.name])
		{
			icon = '<img class="useragent-icon" src="' + (useragents_icons[this.point.name]) + '"/>';
		}

		if (useragents_urls[this.point.name])
		{
			link = '<a href="'+ (useragents_urls[this.point.name]) +'">';
			closelink = '</a>'
		 }

		return '<b>' + link + icon + this.point.name + closelink + '</b>: '+ Highcharts.numberFormat(this.percentage, 2, '.') +' %';
	// 	     return '<b>'+ this.point.name +'</b>: '+ Highcharts.numberFormat(this.percentage, 2, '.') +' %';
	}


	var users_pie_label_formatter = function()
	{
		if (this.point.name == 'Others')
		{
			return '<b>'+ this.point.name +'</b>: '+ Highcharts.numberFormat(this.percentage, 2, '.') +' %';
		}

	// 	     return '<b>'+ this.point.name +'</b>: '+ this.value +' \\n '+ this.percentage +' %';
		var icon = "";
		if (users_profile_images[this.point.name])
		{
			icon = '<img class="useragent-icon" src="' + (users_profile_images[this.point.name]) + '"/>';
		}
		return '<b><a href="http://www.twitter.com/'+ this.point.name +'">' + icon + '@'+ this.point.name +'</a></b>: '+ Highcharts.numberFormat(this.percentage, 2, '.') +' %';
	// 	     return '<b>'+ this.point.name +'</b>: '+ Highcharts.numberFormat(this.percentage, 2, '.') +' %';
	}


	var pie_tooltip_formatter = function()
	{
	     return '<b>'+ this.point.name +'</b>: <br/>'+ this.point.y +' tweets <br/>(' + Highcharts.numberFormat(this.percentage, 2, '.') +' %)';
	}


	var users_pie_tooltip_formatter = function()
	{
		if (this.point.name == 'Others')
		{
			return '<b>'+ this.point.name +'</b>: '+ Highcharts.numberFormat(this.percentage, 2, '.') +' %';
		}

		var icon = "";
		if (users_profile_images[this.point.name])
		{
			icon = '<img class="big-user-icon" src="' + (users_profile_images[this.point.name]) + '"/><br/>';
		}
		return '<b><a href="http://www.twitter.com/'+ this.point.name +'">' + icon + '@'+ this.point.name +'</a></b><br/>'+ this.point.y +' tweets <br/>(' + Highcharts.numberFormat(this.percentage, 2, '.') +' %)';
	}

	$(document).ready(function() {
	useragents_chart = new Highcharts.Chart({
	    chart: {
	        renderTo: 'useragents_container',
	        plotBackgroundColor: null,
	        plotBorderWidth: null,
	        plotShadow: false
	    },
	    title: {
	        text: 'User agents'
	    },
	    tooltip: { useHTML: true, formatter: pie_tooltip_formatter  },
	    plotOptions: {
	        pie: {
	            allowPointSelect: true,
	            cursor: 'pointer',
	            dataLabels: {
	                enabled: true,
	                color: '#000000',
	                connectorColor: '#000000',
	                useHTML: true,
	                formatter: useragent_pie_label_formatter
	            }
	        }
	    },
	    series: [{
	        type: 'pie',
	        name: 'Tweets per user agent',
	        data: <?php echo $useragents_json; ?>,

	    }]
	});


	users_chart = new Highcharts.Chart({
	    chart: {
	        renderTo: 'users_container',
	        plotBackgroundColor: null,
	        plotBorderWidth: null,
	        plotShadow: false
	    },
	    title: {
	        text: 'Users'
	    },
	    tooltip: {	useHTML: true, formatter: users_pie_tooltip_formatter },
	    plotOptions: {
	        pie: {
	            allowPointSelect: true,
	            cursor: 'pointer',
	            dataLabels: {
	                enabled: true,
	                color: '#000000',
	                connectorColor: '#000000',
	                useHTML: true,
	                formatter: users_pie_label_formatter
	            }
	        }
	    },
	    series: [{
	        type: 'pie',
	        name: 'Tweets per user agent',
	        data: <?php echo $users_json; ?>
	    }]
	    ,colors: <?php echo $users_colors_json; ?>
	});


	hourschart = new Highcharts.Chart({
	    chart: {
	        renderTo: 'hours_container',
	        type: 'column'
	    },
	    title: {
	        text: 'Most popular hour of the day for tweeting'
	    },
		xAxis: {
			categories: ['0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31'],
			tickmarkPlacement: 'between'
		},
	    series: [{
	        name: 'Total tweets during this hour',
	        data: <?php echo $hours_json; ?>
	    }]
	});


	weekchart = new Highcharts.Chart({
	    chart: {
	        renderTo: 'week_container',
	        type: 'column'
	    },
	    title: {
	        text: 'Most popular day of the week for tweeting'
	    },
		xAxis: {
			categories: ['(null)','Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
			tickmarkPlacement: 'between'
		},
	    series: [{
	        name: 'Total tweets during this weekday',
	        data: <?php echo $week_json; ?>
	    }]
	});


	monthchart = new Highcharts.Chart({
	    chart: {
	        renderTo: 'month_container',
	        type: 'column'
	    },
	    title: {
	        text: 'Most popular day of the month for tweeting'
	    },
		xAxis: {
			categories: ['0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31'],
			tickmarkPlacement: 'between'
		},
	    series: [{
	        name: 'Total tweets during this day',
	        data: <?php echo $month_json; ?>
	    }]
	});


	timezonescatterchart = new Highcharts.Chart({
	    chart: {
	        renderTo: 'timezonescatter_container',
	        type: 'scatter'
	    },
	    title: {
	        text: 'Tweets by hour and origin timezone'
	    },
		xAxis: {
			title: 'Timezone (UTF offset)',
// 			categories: ['-12','-11','-10','-9','-8','-7','-6','-5','-4','-3','-2','-1','0','1','2','3','4','5','6','7','8','9','10','11','12'],
			tickmarkPlacement: 'between',
			min: -12, max: 12,
			tickInterval: 1,
			gridLineWidth:1,
		},
		yAxis: {
			title: 'Time of tweeting',
			tickmarkPlacement: 'between',
			min: 0, max: 23,
			tickInterval: 1,
		},
	    series: [{
	        name: 'Tweeting amount',
	        color: 'rgba(83, 83, 223, .5)',
	        data: <?php echo $timezone_scatter_json; ?>
	    }]
	});


	timezonescatterchart = new Highcharts.Chart({
	    chart: {
	        renderTo: 'geoscatter_container',
	        type: 'scatter'
	    },
	    title: {
	        text: 'Geolocated tweets'
	    },
		xAxis: {
			title: 'Longitude',
// 			categories: ['-12','-11','-10','-9','-8','-7','-6','-5','-4','-3','-2','-1','0','1','2','3','4','5','6','7','8','9','10','11','12'],
// 			tickmarkPlacement: 'between',
			min: -180, max: 180,
// 			tickInterval: 1,
			gridLineWidth:1,
			tickInterval:20
		},
		yAxis: {
			title: 'Latitude',
// 			tickmarkPlacement: 'between',
			min: -90, max: 90,
// 			tickInterval: 1,
			gridLineWidth:1,
			tickInterval:10
		},
	    series: [{
	        name: 'Tweeting amount',
	        color: 'rgba(83, 83, 223, .25)',
	        data: <?php echo $geo_scatter_json; ?>
	    }]
	});



	});

});
</script>


</body>
</html>
