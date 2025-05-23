// Se dejó los campos de la colección categoría dentro de la entidad Job

// TODO: Crear mapper
class Job {
  final String id;
  final String name;
  final String categoryName;
  final String categoryNameRef;

  Job(
      {required this.id,
      required this.name,
      required this.categoryName,
      required this.categoryNameRef});
}
