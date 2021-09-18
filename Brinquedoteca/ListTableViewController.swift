//
//  ListTableViewController.swift
//  Brinquedoteca
//
//  Created by Lucas Dev on 07/09/21.
//

import UIKit
import Firebase

class ListTableViewController: UITableViewController {
    
    let collection = "brinquedoList"
    
    var brinquedoList: [BrinquedoItem] = []

    lazy var firestore: Firestore = {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        
        let firestore = Firestore.firestore()
        firestore.settings = settings
        
        return firestore
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadBrinquedoList()
    }
    
    var listener: ListenerRegistration!
    
    func loadBrinquedoList() {
        listener = firestore.collection(collection).order(by: "toy", descending: false).addSnapshotListener(includeMetadataChanges: true, listener: {
            snapshot, error in
            
            if let error = error {
                print(error)
            } else {
                guard let snapshot = snapshot else {return}
                
                print("total de documentos alterados: \(snapshot.documentChanges.count)")
                
                if snapshot.metadata.isFromCache || snapshot.documentChanges.count > 0 {
                    self.showItemsFrom(snapshot)
                }
            }
        })
    }
    
    func showItemsFrom(_ snapshot: QuerySnapshot) {
        brinquedoList.removeAll()
        
        for document in snapshot.documents {
            let data = document.data()
            if let toy = data["toy"] as? String,
               let donor = data["donor"] as? String,
               let address = data["address"] as? String,
               let phone = data["phone"] as? String,
               let status = data["status"] as? String {
                let brinquedoItem = BrinquedoItem(id: document.documentID, toy: toy, donor: donor, address: address, phone: phone, status: status)
                brinquedoList.append(brinquedoItem)
            }
        }
        
        tableView.reloadData()
    }
    
    func showAlertForItem(_ item: BrinquedoItem? = nil) {
        let alert = UIAlertController(title: "Brinquedo", message: "Entre com as informações do brinquedo", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Nome do Brinquedo"
            textField.text = item?.toy
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Nome do Doador"
            textField.text = item?.donor
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Endereço do Doador"
            textField.text = item?.address
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Telefone do doador"
            textField.text = item?.phone
        }
        
        alert.addTextField { textField in
            textField.placeholder = "(novo, usado, precisa de reparos)"
            textField.text = item?.status
        }
        
        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
            guard let toy = alert.textFields?.first?.text,
                  let donor = alert.textFields![1].text,
                  let address = alert.textFields![2].text,
                  let phone = alert.textFields![3].text,
                  let status = alert.textFields![4].text
            else {return}
            
            let data: [String: Any] = ["toy": toy, "donor": donor, "address": address, "phone": phone, "status": status]
            
            if let item = item {
                self.firestore.collection(self.collection).document(item.id).updateData(data)
            } else {
                self.firestore.collection(self.collection).addDocument(data: data)
            }
        }
        
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func addToy(_ sender: UIBarButtonItem) {
        showAlertForItem()
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return brinquedoList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let brinquedoItem = brinquedoList[indexPath.row]
        cell.textLabel?.text = brinquedoItem.toy
        cell.detailTextLabel?.text = brinquedoItem.status

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let brinquedoItem = brinquedoList[indexPath.row]
        showAlertForItem(brinquedoItem)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let brinquedoItem = brinquedoList[indexPath.row]
            firestore.collection(collection).document(brinquedoItem.id).delete()
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
