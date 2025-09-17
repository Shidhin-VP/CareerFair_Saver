// lib/pages/home_page.dart

import 'package:careerfair/pages/datePage.dart';
import 'package:careerfair/widgets/provider/providerFile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final updateData = Provider.of<UpdateData>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Date Filter",style: TextStyle(fontFamily: "Asimovian"),),
        centerTitle: true,
        elevation: 5,
        backgroundColor: Colors.limeAccent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String status = await updateData.addDate(DateTime.now());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: status == "Added"
                  ? Colors.lightGreenAccent
                  : Colors.deepOrangeAccent,
              content: Center(
                child: Text(
                  status == "Added" ? "Date added" : "Date already present",
                  style: TextStyle(
                    color: status == "Added" ? Colors.orangeAccent : null,
                  ),
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: updateData.days.isEmpty
          ? const Center(child: Text("No Dates Yet Added"))
          : ListView.builder(
              itemCount: updateData.days.keys.length,
              itemBuilder: (context, index) {
                String dateKey = updateData.days.keys.elementAt(index);
                return ListTile(
                  leading: CircleAvatar(
                    child: Image.asset("assets/ucLogo/UC.png"),
                  ),
                  title: Center(child: Text(dateKey)),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      updateData.deleteDate(dateKey);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DatePage(dateKey: dateKey),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
