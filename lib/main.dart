import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ToonStoreApp());
}

class ToonStoreApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOONSTORE',
      theme: ThemeData(primarySwatch: Colors.green),
      home: LojaScreen(),
    );
  }
}

class LojaScreen extends StatefulWidget {
  @override
  _LojaScreenState createState() => _LojaScreenState();
}

class _LojaScreenState extends State<LojaScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  List<Map> produtos = [];
  List<Map> carrinho = [];
  String notificacao = '';
  double descontoExtra = 0.0;
  TextEditingController codigoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarProdutos();
    carregarNotificacao();
  }

  void carregarProdutos() async {
    final snapshot = await _db.child('produtos').get();
    final data = snapshot.value as Map?;
    if (data != null) {
      setState(() => produtos = data.entries.map((e) => Map.from(e.value)).toList());
    }
  }

  void carregarNotificacao() async {
    final snap = await _db.child('config/notificacao').get();
    setState(() => notificacao = snap.value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TOONSTORE'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => CarrinhoScreen(carrinho: carrinho)));
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (notificacao.isNotEmpty)
            Container(
              color: Colors.amber,
              padding: EdgeInsets.all(10),
              width: double.infinity,
              child: Text(notificacao, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(
                  controller: codigoController,
                  decoration: InputDecoration(hintText: 'Código promocional'),
                )),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final snap = await _db.child('codigos').get();
                    final codigos = Map<String, dynamic>.from(snap.value ?? {});
                    final code = codigoController.text.trim();
                    if (codigos.containsKey(code)) {
                      setState(() => descontoExtra = (codigos[code]['desconto'] ?? 0) / 100);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Código inválido')));
                    }
                  },
                  child: Text('Aplicar'),
                )
              ],
            ),
          ),
          Expanded(child: GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 3 / 4,
            ),
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final p = produtos[index];
              final descontoCat = p['categoria'] == 'Eletrónicos' ? 0.2 : 0.0;
              final preco = (p['precoBase'] ?? 0) * (1 - descontoCat) * (1 - descontoExtra);

              return Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.shopping_bag, size: 60, color: Colors.green),
                    Text(p['nome'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('€${preco.toStringAsFixed(2)}'),
                    ElevatedButton(
                      onPressed: () {
                        carrinho.add({'produto': p['nome'], 'preco': preco});
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Adicionado ao carrinho')));
                      },
                      child: Text('Comprar'),
                    )
                  ],
                ),
              );
            },
          )),
        ],
      ),
    );
  }
}

class CarrinhoScreen extends StatelessWidget {
  final List<Map> carrinho;
  CarrinhoScreen({required this.carrinho});

  @override
  Widget build(BuildContext context) {
    double total = carrinho.fold(0, (sum, item) => sum + (item['preco'] ?? 0));
    return Scaffold(
      appBar: AppBar(title: Text('Carrinho')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...carrinho.map((item) => ListTile(
              title: Text(item['produto']),
              trailing: Text('€${item['preco'].toStringAsFixed(2)}'),
            )),
            Divider(),
            Text('Total: €${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compra finalizada!')));
                Navigator.pop(context);
              },
              child: Text('Finalizar Compra'),
            )
          ],
        ),
      ),
    );
  }
}