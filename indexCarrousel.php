<!DOCTYPE html>
<html lang="en" >
<head>
  <meta charset="UTF-8">
  <title>VISOR SPDR</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="./normalize.min.css">
<link rel="stylesheet" href="./style.css">

</head>
<body>
<?php
    //Recibir la url del directorio http a mostrar
    $matches = array();

    $uri=$_GET["uri"];//Habilitar para prod
    /*URL CON LA QUE SE PROBÓ*/
   // $uri="http://localhost:9091/climax/capture_event/media/35000101/2021-01-22/2021-01-22_185522_176_02/";
?>
<!-- partial:index.partial.html -->

               

<?php

// Pruebas de compatibilidad
//1_ comentar definicion de funcion str_contains
// 2_ comentar checkeo if(count($matches[2])==1)
                    // Definiendo funcion substring si no existe
                /*  if (!function_exists('str_contains')) {
                  function str_contains(string $haystack, string $needle): bool
                 {
                  return '' === $needle || false !== strpos($haystack, $needle);
                   }
                  }*/
                 // fin de definicion de funcion exists 
                if(!empty($uri)){

                preg_match_all("/(a href\=\")([^\?\"]*)(\")/i", file_get_contents($uri), $matches);
               
                if(count($matches[2])==1){
                    echo '<h1>No hay fotos en este directorio</h1>';
                    echo ' <h1>'.var_dump($matches[2]).'</h1>';
                    
                    die();
                }

  ?>
            <section>
            <div class="container">
            <div class="carousel">
            <input type="radio" name="slides" checked="checked" id="slide-1">
<?php
             $indice=2;// comenzamos del 2 porque el uno ya sale por html
                foreach($matches[2] as $match){
              //     if (str_contains($match, '.')){// para que muestre solo si hay archivo, sino muestra directorio
                  //echo $indice;
                  echo '<input type="radio" name="slides" id="slide-'.$indice.'">';
                  $indice++;
                  
                  
              // }


            }
 ?>           

            

            <ul class="carousel__slides">
  <?php              

               

                foreach($matches[2] as $match){

              //  if (str_contains($match, '.')){
  ?>                  
                     <li class="carousel__slide">
                    <figure>
                        <div>
   <?php                         
                           // echo '<img src="'.$uri.$match.'>';
                            // Se carga la foto para ver en grande, con ampliación
                        echo  '<img src="'.$uri.$match .'"  height="50" />';
                         // echo '<img src="https://picsum.photos/id/1041/800/450" alt="">'
    ?>                          
                        </div>
                        <figcaption>
                                <?php
                               $parsed = get_string_between($uri, 'media/', '/');
                                 echo "<h1>".$parsed."</h1>";
                                  ?>
                            <span class="credit">Photo: Visor Spider</span>
                        </figcaption>
                    </figure>
                
                </li>


<?php              
  
             //    }//fin   if (str_contains($match, '.')){ es para que no muestre el directorio como una imagen

                 }
                 } else{
                   echo '<h2>Debe enviar una URL valida para visualizar las imagenes, debe ser un directorio http valido<br>
                    con el formato de ejemplo :  http://localhost:81/LB/IMAGEN5.PHP?uri=http://10.24.34.23:8899/capture_event/media/35000101/2021-01-22/2021-01-22_185522_176_02/ lo que usted envio fue  ->  '.$uri.'</h2>';
                 }
?>
               
                
            </ul>    
            <ul class="carousel__thumbnails">

                <!-- Crear un ciclo apuntanto desde slide-n con la fot n hasta n fotos-->
               

 <?php 
                $indice=1;
                foreach($matches[2] as $match){
                //   if (str_contains($match, '.')){// para que muestre solo si hay archivo, sino muestra directorio
                   echo '<li>';
                  // ECHO $indice;
                  // echo $match;
                   echo ' <label for="slide-'.$indice.'"><img src="'.$uri.$match.'" ></label>';
                   $indice++;
                  
                   echo '</li>';
           //    }


            }// fin ciclo
  ?>               
               
                   
                
               
            </ul>
        </div>
    </div>
</section>
<!-- partial -->
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
