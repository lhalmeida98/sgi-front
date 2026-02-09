import '../domain/models/categoria.dart';
import '../services/categorias_service.dart';
import 'base_provider.dart';

class CategoriasProvider extends BaseProvider {
  CategoriasProvider(this._service);

  final CategoriasService _service;
  List<Categoria> categorias = [];

  Future<void> fetchCategorias() async {
    setLoading(true);
    try {
      categorias = await _service.fetchCategorias();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createCategoria(Categoria categoria) async {
    setLoading(true);
    try {
      await _service.createCategoria(categoria);
      await fetchCategorias();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateCategoria(Categoria categoria) async {
    setLoading(true);
    try {
      await _service.updateCategoria(categoria);
      await fetchCategorias();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
