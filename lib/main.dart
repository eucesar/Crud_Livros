// Importa utilitários para trabalhar com JSON
import 'dart:convert';

// Flutter UI e cliente HTTP
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Configuração da API
class ApiConfig {
  static const String baseUrl = "https://generic-items-api-a785ff596d21.herokuapp.com";
  static const String rm = "98007";
  
  static String livros() => "$baseUrl/api/livros/$rm";
  static String criarLivro() => "$baseUrl/api/livros";
  static String livroById(String id) => "$baseUrl/api/livros/$rm/$id";
}

// Modelo do livro
class Book {
  final String id;
  final String titulo;
  final String descricao;
  final double valor;
  final String imagemUrl;

  Book({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.imagemUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'].toString(),
      titulo: json['titulo'],
      descricao: json['descricao'],
      valor: json['valor'].toDouble(),
      imagemUrl: json['imagemUrl'],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Book> livros = [];

  @override
  void initState() {
    super.initState();
    fetchLivros();
  }

  Future<void> fetchLivros() async {
    final response = await http.get(Uri.parse(ApiConfig.livros()));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        livros = data.map((e) => Book.fromJson(e)).toList();
      });
    }
  }

  void goToForm({Book? livro}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookFormPage(livro: livro)),
    );
    fetchLivros();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Livros")),
      body: ListView.builder(
        itemCount: livros.length,
        itemBuilder: (context, index) {
          final livro = livros[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: livro.imagemUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        livro.imagemUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported, size: 30),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 30),
                    ),
              title: Text(livro.titulo),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(livro.descricao),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${livro.valor.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(livro),
              ),
              onTap: () => goToForm(livro: livro),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => goToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showDeleteDialog(Book livro) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmação"),
        content: Text("Deseja realmente excluir o livro '${livro.titulo}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteLivro(livro);
    }
  }

  Future<void> _deleteLivro(Book livro) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.livroById(livro.id)),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livro excluído com sucesso!')),
        );
        fetchLivros();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir livro: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }
}

class BookFormPage extends StatefulWidget {
  final Book? livro;

  const BookFormPage({super.key, this.livro});

  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController valorController = TextEditingController();
  final TextEditingController imagemUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.livro != null) {
      tituloController.text = widget.livro!.titulo;
      descricaoController.text = widget.livro!.descricao;
      valorController.text = widget.livro!.valor.toString();
      imagemUrlController.text = widget.livro!.imagemUrl;
    }
  }

  Future<void> saveLivro() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> data = {
        "titulo": tituloController.text,
        "descricao": descricaoController.text,
        "valor": double.parse(valorController.text),
        "imagemUrl": imagemUrlController.text,
        "rm": ApiConfig.rm,
      };

      try {
        http.Response response;
        if (widget.livro == null) {
          response = await http.post(
            Uri.parse(ApiConfig.criarLivro()),
            headers: {"Content-Type": "application/json"},
            body: json.encode(data),
          );
        } else {
          response = await http.put(
            Uri.parse(ApiConfig.livroById(widget.livro!.id)),
            headers: {"Content-Type": "application/json"},
            body: json.encode(data),
          );
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Livro salvo com sucesso!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: ${response.statusCode} - ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> deleteLivro() async {
    if (widget.livro == null) return;
    
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.livroById(widget.livro!.id)),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Livro excluído!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e")),
      );
    }
  }

  Future<bool> showConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmação"),
        content: const Text("Deseja realmente excluir este livro?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.livro != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Livro" : "Novo Livro"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: tituloController,
                decoration: const InputDecoration(labelText: "Título do Livro"),
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha o título' : null,
              ),
              TextFormField(
                controller: descricaoController,
                decoration: const InputDecoration(labelText: "Descrição"),
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha a descrição' : null,
              ),
              TextFormField(
                controller: valorController,
                decoration: const InputDecoration(
                  labelText: "Valor (R\$)",
                  prefixText: "R\$ ",
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Preencha o valor';
                  if (double.tryParse(v) == null) return 'Valor inválido';
                  return null;
                },
              ),
              TextFormField(
                controller: imagemUrlController,
                decoration: const InputDecoration(
                  labelText: "URL da Imagem",
                  hintText: "Ex: https://exemplo.com/imagem.jpg",
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha a URL da imagem' : null,
                onChanged: (value) {
                  setState(() {});
                },
              ),
              if (imagemUrlController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("Preview da Imagem:"),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imagemUrlController.text,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 50),
                                Text("Imagem não encontrada"),
                                Text("Verifique a URL", style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saveLivro,
                      child: const Text("Salvar"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                  ),
                ],
              ),
              if (isEditing) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      final confirm = await showConfirmDialog(context);
                      if (confirm == true) {
                        deleteLivro();
                      }
                    },
                    child: const Text("Excluir"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    tituloController.dispose();
    descricaoController.dispose();
    valorController.dispose();
    imagemUrlController.dispose();
    super.dispose();
  }
}

void main() {
  runApp(const BooksApp());
}

class BooksApp extends StatelessWidget {
  const BooksApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Books App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}