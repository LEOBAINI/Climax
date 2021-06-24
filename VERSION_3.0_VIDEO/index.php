

<?php
imprimirCabecera();
echo '<body>';

    //Recibir la url del directorio http a mostrar
    $matches = array();

    $uri=$_GET["uri"];//Habilitar para prod
    /*URL CON LA QUE SE PROBÓ*/
   // $uri="http://localhost:9091/climax/capture_event/media/35000101/2021-01-22/2021-01-22_185522_176_02/";

                 $matches=contenidoDelDirectorio($uri);

                 verificarUrlVacia($uri);
                 inicioSeccion();

                 cargarIndicesSlide($matches);

                 inicioDeLista();

                 cargarImagenAmpliada($uri,$matches);   
                 

                 finDeLista();
                
                 mostrarMiniaturas($uri,$matches);

                 finSeccion();

                 mostrarVideo($uri,$matches);
                 




   
function get_string_between($string, $start, $end){
    $string = ' ' . $string;
    $ini = strpos($string, $start);
    if ($ini == 0) return '';
    $ini += strlen($start);
    $len = strpos($string, $end, $ini) - $ini;
    return substr($string, $ini, $len);
}
function verificarUrlVacia($uri){
    if(!empty($uri)){
                 /*
                 Busca en subject todas las coincidencias de la expresión regular dada en pattern y las introduce en matches en el orden especificado por flags.

                 Después haber encontrado la primera coincidencia, las búsquedas subsiguientes continuarán desde el final de la dicha coincidencia.*/   
               $matches=contenidoDelDirectorio($uri);
               
                if(count($matches[2])==1){
                    echo '<h1>No hay fotos en este directorio</h1>';
                    echo ' <h1>'.var_dump($matches[2]).'</h1>';
                    
                    die();
                }
}
}
function inicioSeccion(){
            echo '<section>';
            echo '<div class="container">';
            echo '<div class="carousel">';
            echo '<input type="radio" name="slides" checked="checked" id="slide-1">';
}
function finSeccion(){
    echo '</ul>';
    echo '</div>';
    echo '</div>';
    echo '</section>';
}
function imprimirCabecera(){
   echo '<!DOCTYPE html>';
   echo '<html lang="en" >';
   echo '<head>';
   echo '<meta charset="UTF-8">';
   echo '<title>VISOR SPDR</title>';
   echo '<meta name="viewport" content="width=device-width, initial-scale=1">';
   echo '<link rel="shortcut icon" href="./img/prosegur-logo-0.png">';
   echo '<link rel="stylesheet" type="text/css" href="css/normalize.min.css">';
   echo '<link rel="stylesheet" type="text/css" href="css/style.css">';
   echo '<link rel="stylesheet" type="text/css" href="css/bootstrap.min.css">';
   echo '<script type="text/javascript" src="js/jquery-3.3.1.slim.min.js"></script>';
   echo '<script type="text/javascript" src="js/bootstrap.min.js"></script>';   
   echo '</head>';
   
   
  

    
}


function cargarIndicesSlide($matches){
                // comenzamos del 2 porque el uno ya sale por html
                $indice=2;
                foreach($matches[2] as $match){
                echo '<input type="radio" name="slides" id="slide-'.$indice.'">';
                $indice++;
              }
}
function contenidoDElDirectorio($uri){
     $matches=array();
     preg_match_all("/(a href\=\")([^\?\"]*)(\")/i", file_get_contents($uri), $matches);
     return $matches;

}

function inicioDeLista(){
       
     echo '<ul class="carousel__slides">';
   

}
function finDeLista(){
    ?>
      </ul>    
      <ul class="carousel__thumbnails" onclick="ocultar()">
    <?php
}
function mostrarCodigoConexion($uri){
  $parsed = get_string_between($uri, 'media/', '/');
   echo '<h1>CÓDIGO DE CONEXIÓN '.$parsed.'</h1>';
}
function cargarImagenAmpliada($uri,$matches){

    $indice=0;
    foreach($matches[2] as $match){    

         if ($indice>0){
                    echo '<li class="carousel__slide">';
                    echo '<figure>';
                    echo '<div id="imagenGrande">';
                      
                           // echo '<img src="'.$uri.$match.'>';
                            // Se carga la foto para ver en grande, con ampliación
                    echo  '<img src="'.$uri.$match .'"  height="50" " onclick="mostrarVideo()" />';
                         // echo '<img src="https://picsum.photos/id/1041/800/450" alt="">'
                     
                    echo '</div>';

                    echo '<figcaption>';

                                
                    mostrarCodigoConexion($uri);           
                               
                    echo '<span class="credit" id="mensaje"> Click en la imagen para ver video</span>';
                    echo '</figcaption>';
                    echo '</figure>';
                
                     echo '</li>';


         }   
    $indice++;           
  
            

                 }
}
function mostrarMiniaturas($uri,$matches){
     $indice=0;
     
                foreach($matches[2] as $match){
                if ($indice>0){
               
                   echo '<li>';
                   echo ' <label for="slide-'.$indice.'"><img src="'.$uri.$match.'" ></label>';
                           
                   echo '</li>';
           
                    }

                      $indice++;
            }// fin ciclo
       
      
}
function mostrarImagen($imagen,$esPrimera){
    
 if($esPrimera==1){
    echo '<div class="carousel-item active">';
    echo '<img class="d-block w-100" src="'.$imagen.'" onclick="ocultar()">';
    echo '</div>';  
    }else{
    echo '<div class="carousel-item ">';
    echo '<img class="d-block w-100" src="'.$imagen.'" onclick="ocultar()">';
    echo '</div>'; 
    }
   
}
function mostrarVideo($uri,$matches){
 ?>
    
    <div id="videoSpider" class="carousel " data-pause="false" onclick="ocultar()">
    <div class="carousel-inner"> 
    <?php   
     $i=1;
     $indiceDirectorio=0;
    
    foreach($matches[2] as $match){  
    if($indiceDirectorio>0){   
    mostrarImagen($uri.$match,$i);  
    $i=0;   
   
   }
    $indiceDirectorio++;
}

    ?>
    
 
    </div>

    </div>

    <?php

}
/*
Estructura del array:
Array ( [0] => Array ( 
                    [0] => a href="/climax/capture_event/media/35000101/2021-01-22/" 
                    [1] => a href="0.jpg" 
                    [2] => a href="1.jpg" 
                    [3] => a href="2.jpg" 
                    [4] => a href="3.jpg" 
                    [5] => a href="4.jpg" 
                    [6] => a href="DSC_7140.jpg" 
        )
        [1] => Array ( 
                    [0] => a href=" 
                    [1] => a href=" 
                    [2] => a href=" 
                    [3] => a href=" 
                    [4] => a href=" 
                    [5] => a href=" 
                    [6] => a href=" 
        )
        [2] => Array ( 
                    [0] => /climax/capture_event/media/35000101/2021-01-22/ 
                    [1] => 0.jpg 
                    [2] => 1.jpg 
                    [3] => 2.jpg 
                    [4] => 3.jpg 
                    [5] => 4.jpg 
                    [6] => DSC_7140.jpg 
                    ) 
        [3] => Array (
                    [0] => " 
                    [1] => " 
                    [2] => " 
                    [3] => " 
                    [4] => " 
                    [5] => " 
                    [6] => " 
) 
)
*/

      
    ?>
    <script>

  $(document).ready(function(){
      $('.carousel').carousel({autoplayTimeout:100, autoplayHoverPause:false,interval: 300,pause: "false"});
   
     $('.carousel').carousel('cycle');
    
     
     
     
      
     $("#videoSpider").hide();
  });

  $(function(){
        $("#BotonParaEsconder").click(function(){
            $("#videoSpider").hide();
             $("#imagenGrande").show();
            
        });
    });
  $(function(){
        $("#BotonParaMostrar").click(function(){
           
            $("#videoSpider").show();
            $("#imagenGrande").hide();
        });
    });
  function ocultar(){
     $("#videoSpider").hide();
      $("#imagenGrande").show();
      mensaje_ver_video();
      
  }

  function mostrarVideo(){
     $("#videoSpider").show();
      $("#imagenGrande").hide();
      mensaje_ver_imagen();
      
  }
  function mensaje_ver_video(){
    document.getElementById("mensaje").innerHTML = "Pulse la imagen para ver video"
  }
  function mensaje_ver_imagen(){
    document.getElementById("mensaje").innerHTML = "Pulse la el video para ver imagen"
  }
</script>

</body>
</html>