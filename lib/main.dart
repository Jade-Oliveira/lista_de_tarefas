import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(primary: Colors.white),
        ),
    ),
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: [
                //expandimos o TextField para ter a maior largura possível
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                        labelText: 'Nova Tarefa',
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent)
                  ),
                  onPressed: () {},
                  child: Text('ADD', style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  //função que vai retornar o arquivo que vou utilizar para salvar
//tudo que envolve leitura e tratamento de arquivos precisa ser assíncrono já que não ocorre imediatamente
  Future<File> _getFile() async {
    //essa função vai pegar o diretório onde posso armazenar os documentos do meu app
    final directory = await getApplicationDocumentsDirectory();
    //aqui vou abrir o arquivo através do file
    return File('${directory.path}/data.json');
  }

//função para salvar os dados
  Future<File> _saveData() async {
    //transforma a lista em json e armazena numa string
    String data = json.encode(_toDoList);

    //pegamos o arquivo onde vamos salvar
    final file = await _getFile();

    //vamos escrever nossos dados da lista de tarefas como texto dentro do nosso arquivo
    return file.writeAsString(data);
  }

  //função para ler os dados
  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      //tenta ler o arquivo como string e retorna
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
