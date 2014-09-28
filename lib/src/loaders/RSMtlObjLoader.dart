part of three;

class RSMtlObjLoader {
  String mtlFile;
  String objFile;
  Object3D object3d;
  List<Mesh> meshes = new List();
  MaterialCreator matCreator;
  Mesh mesh;

  RSMtlLoader mtlLoader;
  RSObjLoader objLoader;

  Completer completer;

  RSMtlObjLoader(this.objFile, [this.mtlFile]) {
    this.mtlFile = this.mtlFile == null ? this.objFile.replaceAll(".obj", ".mtl") : this.mtlFile;

    completer = new Completer<Object3D>();

    mtlLoader = new RSMtlLoader(this.mtlFile);
    objLoader = new RSObjLoader();
  }

  Future<Object3D> load() {

    this.mtlLoader.load(this.mtlFile).then(MtlLoaded);

    return completer.future;
  }

  MtlLoaded(_creator) {
    this.matCreator = _creator;
    this.matCreator.preload();
    objLoader.matIndexes = this.matCreator.materialsIndexes;
    objLoader.load(this.objFile).then(ObjLoaded);
  }

  ObjLoaded(_obj) {
    this.object3d = _obj;
    MeshFaceMaterial combMat = new MeshFaceMaterial(this.matCreator.materials.values.toList());

    this.meshes.addAll(this.object3d.children);
    this.meshes.forEach((Mesh m)=>m.geometry.materials=this.matCreator.materials.values.toList());
    this.object3d.children.forEach((Mesh m) => m.material = combMat);

    this.completer.complete(this.object3d);

    /*Geometry combGeo=object3d.children[0].geometry;
    combGeo.materials=matCreator.materials.values.toList();
    this.mesh=new Mesh(combGeo,combMat);
    this.completer.complete(this.mesh);*/
  }

  Object3D getAnother() {
    MeshFaceMaterial combMat = new MeshFaceMaterial(this.matCreator.materials.values.toList());

    Object3D obj = new Object3D()
        ..receiveShadow = true
        ..castShadow = true;

    this.meshes.forEach((Mesh m) {
      Mesh newMesh = new Mesh(m.geometry, combMat);
      obj.add(newMesh);
    });

    return obj;

    /*Geometry combGeo=object3d.children[0].geometry;
    combGeo.materials=matCreator.materials.values.toList();
    return new Mesh(combGeo,combMat);*/
  }


}
