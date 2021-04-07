<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Prosegur</title>
<style type="text/css">

body
{
 background:#fff;
}
img
{
 width:auto;
 box-shadow:0px 0px 20px #cecece;
 -moz-transform: scale(0.7);
 -moz-transition-duration: 0.6s; 
 -webkit-transition-duration: 0.6s;
 -webkit-transform: scale(0.7);
 -ms-transform: scale(0.7);
 -ms-transition-duration: 0.6s; 
}
img:hover
{
  box-shadow: 20px 20px 20px #dcdcdc;
 -moz-transform: scale(1.8);
 -moz-transition-duration: 0.6s;
 -webkit-transition-duration: 0.6s;
 -webkit-transform: scale(1.8);
 -ms-transform: scale(1.8);
 -ms-transition-duration: 0.6s;
 
}
h1{
font-family: Arial;
color:red;
}
</style>
</head>
<body>
<?php
if (!function_exists('str_contains')) {
        function str_contains(string $haystack, string $needle): bool
        {
            return '' === $needle || false !== strpos($haystack, $needle);
        }
    }
	
    $matches = array();
    $uri=$_GET["uri"];
    /*URL CON LA QUE SE PROBÓ*/
  // $uri="http://localhost:9091/climax/capture_event/media/35000101/2021-01-22/2021-01-22_185522_176_02/";
   
   $parsed = get_string_between($uri, 'media/', '/');
   echo '<h1>'.$parsed.'</h1>';
   

    
    if(!empty($uri)){

    preg_match_all("/(a href\=\")([^\?\"]*)(\")/i", file_get_contents($uri), $matches);
   // var_dump($matches[2]) ;

    foreach($matches[2] as $match){

   if (str_contains($match, '.')){
      echo '<a href="'.$uri.$match .'"><img src="'.$uri.$match .'"  height="300" /></a>';
  
    }

   }
   } else{
		echo '<h2>Debe enviar una URL valida para visualizar las imagenes, debe ser un directorio http valido<br>
		con el formato de ejemplo :  http://localhost:81/LB/IMAGEN5.PHP?uri=http://10.24.34.23:8899/capture_event/media/35000101/2021-01-22/2021-01-22_185522_176_02/ lo que usted envio fue  ->  '.$uri.'</h2>';
	}
  /*  }
	catch(Exception $e){
         echo $e->getMessage();
         die();
    }*/



   
function get_string_between($string, $start, $end){
    $string = ' ' . $string;
    $ini = strpos($string, $start);
    if ($ini == 0) return '';
    $ini += strlen($start);
    $len = strpos($string, $end, $ini) - $ini;
    return substr($string, $ini, $len);
}


?>
</body>
</html>