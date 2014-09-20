part of three;

/**
 * @author mrdoob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author seguins
 *
 */

class RSMtlLoader extends Loader {

  String baseUrl;
  MTLOptions options;
  var crossOrigins;
  
  RSMtlLoader(this.baseUrl,[this.options,this.crossOrigins]) : super();

  Future<MaterialCreator> load(String url) =>
      HttpRequest.request(url, responseType: "String")
      .then((req) => _parse(req.response));

  _parse(text) {
    
    List<String> lines = text.split('\n');
    Map<String,dynamic> info;
    String delimiter_pattern = "/\s+/";
    Map<String,Map<String,dynamic>> materialsInfo = new Map<String,Map<String,dynamic>>();

    for ( var i = 0; i < lines.length; i ++ ) {

      String line = lines[ i ];
      line = line.trim();

      if ( line.length == 0 || line[0] == '#' ) {

        // Blank line or comment ignore
        continue;
      }

      int pos = line.indexOf( ' ' );

      String key = ( pos >= 0 ) ? line.substring( 0, pos ) : line;
      key = key.toLowerCase();

      String value = ( pos >= 0 ) ? line.substring( pos + 1 ) : "";
      value = value.trim();

      if ( key == "newmtl" ) {

        // New material

        info=new Map<String,dynamic>();
        info["name"]=value;
        materialsInfo[ value ] = info;

      } else if ( info!=null ) {

        if ( key == "ka" || key == "kd" || key == "ks" ) {

          var ss = value.split(" ");
          info[ key ] = [double.parse( ss[0] ), double.parse( ss[1] ),double.parse( ss[2] ) ];

        } else {

          info[ key ] = value;

        }

      }

    }

    var materialCreator = new MaterialCreator(this.baseUrl, this.options, materialsInfo,this.crossOrigins );
    return materialCreator;
  }
}

class MaterialCreator{
  String baseUrl;
  MTLOptions options;
  Map<String,Map<String,dynamic>> materialsInfo;
  Map<String,int> materialsIndexes;
  Map<String,Material> materials=new Map<String,Material>();
  var crossOrigin;
  
  MaterialCreator(this.baseUrl,this.options,this.materialsInfo,this.crossOrigin){ 
    this.materialsInfo= this.convert();
  }
  
  convert(){
    if ( this.options==null ) return materialsInfo;

        Map<String,Map<String,dynamic>> converted = new Map<String,Map<String,dynamic>>();

        for ( var mn in materialsInfo ) {

          // Convert materials info into normalized form based on options

          Map<String,dynamic> mat = materialsInfo[ mn ];

          Map<String,dynamic> covmat = new Map<String,Material>();

          converted[ mn ] = covmat;

          for ( String prop in mat.keys ) {            
      
            bool save = true;
            var value = mat[ prop ];
            String lprop = prop.toLowerCase();

            switch ( lprop ) {

              case 'kd':
              case 'ka':
              case 'ks':

                // Diffuse color (color under white light) using RGB values

                if ( this.options.normalizeRGB ) {

                  value = [ value[ 0 ] / 255, value[ 1 ] / 255, value[ 2 ] / 255 ];

                }

                if ( this.options.ignoreZeroRGBs ) {

                  if ( value[ 0 ] == 0 && value[ 1 ] == 0 && value[ 1 ] == 0 ) {

                    // ignore

                    save = false;

                  }
                }

                break;

              case 'd':

                // According to MTL format (http://paulbourke.net/dataformats/mtl/):
                //   d is dissolve for current material
                //   factor of 1.0 is fully opaque, a factor of 0 is fully dissolved (completely transparent)

                if ( this.options.invertTransparency ) {

                  value = 1 - value;

                }

                break;

              default:

                break;
            }

            if ( save ) {

              covmat[ lprop ] = value;

            }

          }

        }

        return converted;
  }
  
  preload(){
    materialsIndexes=new Map<String,int>();
    int i=0;
    
    for ( String matName in this.materialsInfo.keys ) {
          this.create( matName );
          materialsIndexes[matName]=i;
          i++;
        }
  }
  
  create(String materialName){
// Create material

    Map<String,dynamic> mat = this.materialsInfo[ materialName ];

 Map<String,dynamic> params=new Map<String,dynamic>();

 MeshPhongMaterial newMat=new MeshPhongMaterial();
 newMat.side=2;
 
 var diffuse;

 for ( String prop in mat.keys ) {

   var value = mat[ prop ];

   switch ( prop.toLowerCase() ) {

     // Ns is material specular exponent

     case 'kd':

       // Diffuse color (color under white light) using RGB values

       diffuse= new Color().setRGB(value[0],value[1],value[2]) ;

       break;

     case 'ka':

       // Ambient color (color under shadow) using RGB values
       
       newMat.ambient =new Color().setRGB(value[0],value[1],value[2]) ;

       break;

     case 'ks':

       // Specular color (color when light is reflected from shiny surface) using RGB values
       newMat.specular = new Color().setRGB(value[0],value[1],value[2]) ;

       break;

     case 'map_kd':

       // Diffuse texture map

       newMat.map = this.loadTexture( this.baseUrl + value );
       newMat.map.wrapS = this.options.wrap;
       newMat.map.wrapT = this.options.wrap;

       break;

     case 'ns':

       // The specular exponent (defines the focus of the specular highlight)
       // A high exponent results in a tight, concentrated highlight. Ns values normally range from 0 to 1000.

       newMat.shininess =num.parse(value);

       break;

     case 'd':

       // According to MTL format (http://paulbourke.net/dataformats/mtl/):
       //   d is dissolve for current material
       //   factor of 1.0 is fully opaque, a factor of 0 is fully dissolved (completely transparent)

       if (num.parse(value) < 1 ) {

         newMat.transparent= true;
         newMat.opacity=num.parse( value);

       }

       break;

     default:
       break;

   }

 }

 if ( diffuse!=null ) {
     newMat.ambient = diffuse;
     newMat.color = diffuse;
 }
 
 this.materials[ materialName ] =newMat;
 
 return this.materials[ materialName ];

  }
  
  loadTexture(String url,[var mapping,var onLoad,var onError]){    
    var texture;
    var loader =new Loader();

    if ( loader != null ) {
      texture = loader.load( url, onLoad );
    } else {      
      texture = new Texture();
      
      ImageElement image = new ImageElement();
      image.onLoad.listen((var e){
        texture.image=image;
        texture.needsUpdate=true;
        
        if(onLoad!=null) onLoad(texture);
      });

      if(onError!=null){
        image.onError.listen( onError);
      }

      if ( crossOrigin != null ) image.crossOrigin = crossOrigin;

      image.src = url;      
    }

    texture.mapping = mapping;

    return texture;
  }
  
}

class MTLOptions{
  var side=false;
  var wrap=false;
  var normalizeRGB=false;
  var ignoreZeroRGBs=false;
  var invertTransparency=false;
  
  MTLOptions([this.side,this.wrap,this.normalizeRGB,this.ignoreZeroRGBs,this.invertTransparency]){}
}

