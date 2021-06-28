

<?php
imprimirCabecera();
echo '<body>';

    //Recibir la url del directorio http a mostrar
    $matches = array();

   // $uri=$_GET["uri"];//Habilitar para prod
    if(isset($_GET["uri"])){
      //echo "todo ok";
      $uri=$_GET["uri"];
    }else{
      //echo "todo mal";
      echo "<h1>Ingrese url parámetro para visualizar</h1>";
      echo "<br><h2>Ejemplo http://localhost:81/CLIMAX/index.php<strong>?uri=http://10.25.142.163:8899/capture_event/media/00002066/2021-04-14/2021-04-14_133205_5144_01/</strong></h2>";
       echo '<img id="advertencia" src="./img/caution.jpg">';
      die();
    }
   


    /*URL CON LA QUE SE PROBÓ*/
   // $uri="http://localhost:9091/climax/capture_event/media/35000101/2021-01-22/2021-01-22_185522_176_02/";

                $matches=contenidoDelDirectorio($uri);                
                $imagenes=array();
                $imagenes=$matches[2];// En matches 2 se encuentran los nombres de las fotos
              //   echo('<pre>');
              //  unset($imagenes[0]);// poner comentario para pre
              // var_dump($imagenes);
             //  echo('</pre>');
             //   die();

                 verificarUrlVacia($imagenes);

                 inicioSeccion();

                 cargarIndicesSlide($imagenes);

                 inicioDeLista();

                 cargarImagenAmpliada($uri,$imagenes);                 

                 finDeLista();
                
                 mostrarMiniaturas($uri,$imagenes);

                 finSeccion();

                 mostrarVideo($uri,$imagenes);
                 




   
function get_string_between($string, $start, $end){
    $string = ' ' . $string;
    $ini = strpos($string, $start);
    if ($ini == 0) return '';
    $ini += strlen($start);
    $len = strpos($string, $end, $ini) - $ini;
    return substr($string, $ini, $len);
}
function verificarUrlVacia($imagenes){              
               
                if(count($imagenes)==0){
                    echo '<h1>No hay fotos en este directorio</h1>';
                    echo '<img id="advertencia" src="./img/caution.jpg">';
                                    
                    die();
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

                
                $indice=2;// debe comenzar por el 1 por definicion del css
                foreach($matches as $match){
                // echo '<pre>'.$match.'</pre>';
                echo '<input type="radio" name="slides" id="slide-'.$indice.'">';
                //echo $indice;
                $indice++;
              }
}
function contenidoDElDirectorio($uri){
  $matches=array();
    if(empty($uri)){
      $matches[0]=null;

    }
     else{
     $matches=array();
     preg_match_all("/(a href\=\")([^\?\"]*)(\")/i", file_get_contents($uri), $matches);
   }
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

   
    foreach($matches as $match){    

        
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
}
function mostrarMiniaturas($uri,$matches){
     
     $indice=1;
                foreach($matches as $match){
               
               
                   echo '<li>';
                   echo ' <label for="slide-'.$indice.'"><img src="'.$uri.$match.'" ></label>';
                           
                   echo '</li>';
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
     
    
    foreach($matches as $match){  
    
    mostrarImagen($uri.$match,$i);  
    $i++;   
   
   }
    
}

    ?>
    
 
    </div>

    </div>

    <?php


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
      $('.carousel').carousel({autoplayTimeout:100, autoplayHoverPause:false,interval: 500,pause: "false"});
   
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