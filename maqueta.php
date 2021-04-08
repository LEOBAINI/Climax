<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<meta name="viewport" content="width=device-width"/>
		<link rel="shortcut icon" href=".\favicon-16x16.png">
		<title>Visor SPM</title>
		
		<style type="text/css">
			
#contenedor{
     /*   background-color:#F4ABF2;*/
        border:2px  #152836;
        height: 100%;
}
#precabecera{
       /* background-color:#E5BC7A;*/
      
        height:10%;
        display: flex;       
  		justify-content: center;
  		
}
#cabecera{
       /* background-color:#E5BC7A;*/
       box-shadow: 20px 20px 20px #dcdcdc;
        height:15%;
         display: flex;       
  		justify-content: space-around;
  		align-items: flex-end;
}

#izquierda{
        height:50%;
        box-shadow: 20px 20px 20px #dcdcdc;
        float:left;
        width:100%;
}


img{
	border:6px #152836;
}
img:hover
{
  box-shadow: 20px 20px 20px #dcdcdc;
 
 
   margin: auto;
  /* display:block;*/
   width: 600px;
   height: 480px;
   position: fixed;
   top:20%;
   left:25%;
 
  
 
}
h3{
font-family: Arial;
color:red;

}

		</style>
	</head>
	<body>
		<div id ="contenedor">
			<div id="precabecera">
				<?php
		if (!function_exists('str_contains')) {
        function str_contains(string $haystack, string $needle): bool
        {
            return '' === $needle || false !== strpos($haystack, $needle);
        }
    }
	
    $matches = array();
   // $uri=$_GET["uri"];
    /*URL CON LA QUE SE PROBÓ*/
   $uri="http://localhost:9091/climax/capture_event/media/35000101/2021-01-22/2021-01-22_185522_176_02/";
   
   
  ?>
  
				
	</div>
			<div id ="cabecera">
	<?php
			


    if(!empty($uri)){

    preg_match_all("/(a href\=\")([^\?\"]*)(\")/i", file_get_contents($uri), $matches);
   // var_dump($matches[2]) ;

    foreach($matches[2] as $match){

   if (str_contains($match, '.')){
      echo '<a href="'.$uri.$match .'"><img src="'.$uri.$match .'"  height="135" /></a>';
  
    }

   }
   } else{
		echo '<h2>Debe enviar una URL valida para visualizar las imagenes, debe ser un directorio http valido<br>
		con el formato de ejemplo :  http://localhost:81/LB/IMAGEN5.PHP?uri=http://10.24.34.23:8899/capture_event/media/35000101/2021-01-22/2021-01-22_185522_176_02/ lo que usted envio fue  ->  '.$uri.'</h2>';
	}
				

	
   ?>
 		 </div>
			
			<div id ="izquierda">
				<?php
				$parsed = get_string_between($uri, 'media/', '/');
  	 			echo "<h3>".$parsed."</h3>";
  	 			?>
			</div>
			
			
</div>
	<?php

   
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