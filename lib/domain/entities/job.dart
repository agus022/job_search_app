// TODO: Obtener categories, Obtener jobs de una category específica
class Job {
  final String id;
  final String name;
  final String category;
  final String categoryRef;

  Job(
      {required this.id,
      required this.name,
      required this.category,
      required this.categoryRef});
}

class OficialJob {
  final String id;
  final String oficialRef;
  final String oficioRef;

  OficialJob({
    required this.id,
    required this.oficialRef,
    required this.oficioRef,
  });
}
