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
  final _toDoController = TextEditingController();

  List _toDoList = [];
  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    //como o readData retorna um Future precisamos desse then para chamar a função dele assim que o readData retornar os dados
    //readData retorna uma String que vai ser passado dentro dessa função anônima pelo parâmetro
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data!);
      });
    });
  }

  //vai ler os dados quando o meu app abre, aqui são salvos os dados permanetemente
  //método que é chamado toda vez que inicializamos o estado da nosa tela

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
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: 'Nova Tarefa',
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.blueAccent)),
                  onPressed: _addToDo,
                  child: Text(
                    'ADD',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          //uso o expanded para informar que a lista deve ocupar a tela inteira
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              //builder é um construtor que vai permitir a construção da lista conforme eu for rodando ela
              //ou seja, elementos escondidos não serão renderizados, e portanto não vão consumir recursos
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    //iwdget que vai permitir arrastar para a direita para excluir a tarefa
    return Dismissible(
      //pega o tempo em milisegundos e transforma em string, essa key aceita qualquer string, mas vai ter que ser diferente para todos os itens
      key: Key(DateTime
          .now()
          .microsecondsSinceEpoch
          .toString()),
      background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(Icons.delete, color: Colors.white),
          )),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['ok'] ? Icons.check : Icons.error),
        ),
        //onChanged é chamado quando clico no elemento da lista, passando o parâmetro c como true ou false
        onChanged: (c) {
          setState(() {
            //armazeno esse true ou false no ok do elemento da lista e dá um setState para atualizar a lista com o novo estado
            _toDoList[index]['ok'] = c;
            _saveData();
          });
        },
      ),
      //dentro desse onDismissed terá uma função que será chamada sempre que arrastar o item para a direita para remoção
      onDismissed: (direction) {
        setState(() {
          //duplica o item
          _lastRemoved = Map.from(_toDoList[index]);
          //salvar o item
          _lastRemovedPos = index;
          //removemos o item
          _toDoList.removeAt(index);
          //salva a lista com item já removido
          _saveData();

          final snack = SnackBar(
            content: Text('Tarefa \'${_lastRemoved['title']}\' removida!'),
            action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () {
                  setState(() {
                    //recoloca o item removido na lista
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
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

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      //pego o texto do meu textField
      newToDo['title'] = _toDoController.text;
      //zera o texto do textFiedl assim que clicar no botão para adicionar a tarefa
      _toDoController.text = '';
      //como acabamos de criar a tarefa, inicializa com ela não concluída
      newToDo['ok'] = false;
      //adicionamos um mapa na lista
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  //função que quando puxamos a tela para baixo ela carrega mais dados
  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      //ordena a lista
      _toDoList.sort((a, b){
        if(a['ok'] && !b['ok']) return 1;
        else if (!a['ok'] && b['ok']) return -1;
        else return 0;
      });
      _saveData();
    });

    return null;
  }
}
