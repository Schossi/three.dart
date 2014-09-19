library RSMTLOBJLoader;

import 'dart:html';
import 'package:three/three.dart';
import 'dart:math';
import 'dart:async';
import 'package:vector_math/vector_math.dart';
import 'RSMtlLoader.dart';
import 'RSObjLoader.dart';

class RSMtlObjLoader{
  String mtlFile;
  String objFile;  
  Object3D object3d;
  MaterialCreator matCreator;
  Mesh mesh;
  
  RSMtlLoader mtlLoader;
  RSObjLoader objLoader;
  
  Completer completer;
  
  RSMtlObjLoader(this.objFile,[this.mtlFile]){
    this.mtlFile=this.mtlFile==null?this.objFile.replaceAll(".obj", ".mtl"):this.mtlFile;
    
    completer=new Completer<Mesh>();
    
    mtlLoader=new RSMtlLoader(this.mtlFile);
    objLoader=new RSObjLoader();
  }
  
  Future<Mesh> load() {

    this.mtlLoader.load(this.mtlFile).then(MtlLoaded);
    
    return completer.future;
  }
  
  MtlLoaded(_creator){
    this.matCreator=_creator;
    this.matCreator.preload();
    objLoader.matIndexes=this.matCreator.materialsIndexes;
    objLoader.load(this.objFile).then(ObjLoaded);
  }
  
  ObjLoaded(_obj){
    this.object3d=_obj;              
    MeshFaceMaterial combMat =new MeshFaceMaterial(this.matCreator.materials.values.toList());
    Geometry combGeo=object3d.children[0].geometry;
    combGeo.materials=matCreator.materials.values.toList();
    this.mesh=new Mesh(combGeo,combMat);
    this.completer.complete(this.mesh);
  }
    
 
}