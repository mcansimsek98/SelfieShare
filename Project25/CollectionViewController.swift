//
//  ViewController.swift
//  Project25
//
//  Created by Mehmet Can Şimşek on 15.08.2022.
//


import UIKit
import MultipeerConnectivity

class CollectionViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate, MCAdvertiserAssistantDelegate {


    
    var images = [UIImage]()
    var message = ""

    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCNearbyServiceAdvertiser!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Selfie Share"
        let cameraButton = UIBarButtonItem(title: "📷", style: .plain, target: self, action: #selector(importPicture))
        let hostButton = UIBarButtonItem(title: "➕", style: .plain, target: self, action: #selector(showConnectionPrompt))
        let namesButton = UIBarButtonItem(title: "🔗", style: .plain, target: self, action: #selector(namesOfConnection))
        let messageButton = UIBarButtonItem(title: "📨", style: .plain, target: self, action: #selector(sendMessage))
        navigationItem.rightBarButtonItems = [cameraButton, messageButton]
        navigationItem.leftBarButtonItems = [hostButton, namesButton]
        
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
    }
    
    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting ))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession ))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel ))
        present(ac, animated: true)
    }
    
    
    @objc func namesOfConnection() {
        guard let mcSession = mcSession else { return }
        let connection = mcSession.connectedPeers.description
        let ac = UIAlertController(title: "Connected Peers", message: connection, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(ac, animated: true)
    }
    
    @objc func sendMessage() {
        let ac = UIAlertController(title: "Send Message", message: nil, preferredStyle: .alert)
        ac.addTextField { textField in textField.placeholder = "Write Message" }
        ac.addAction(UIAlertAction(title: "Send", style: .default, handler: { _ in
            guard let text = ac.textFields?[0].text else { return}
            self.message = text
            self.sendTextToPears(message: text)
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func sendTextToPears(message: String) {
            guard let mcSession = mcSession else { return }
            let data = Data(message.utf8)
     
            if mcSession.connectedPeers.count > 0 {
                
                if message != "" {
                    do {
                        try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
                    } catch {
                        let ac = UIAlertController(title: "Send Error", message: error.localizedDescription, preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        present(ac, animated: true)
                    }
                }
                
            }
        }
    
    
    func startHosting(action: UIAlertAction) {
       
        mcAdvertiserAssistant = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "hws-project25")
        mcAdvertiserAssistant.delegate = self
        mcAdvertiserAssistant?.startAdvertisingPeer()
        

    }
    
    func joinSession(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard let mcSession = mcSession else { return }
        let ac = UIAlertController(title: "Do you want to connect", message: " \(peerID.displayName) wants to connect with you." , preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            invitationHandler(true, mcSession)
        }))
        ac.addAction(UIAlertAction(title: "No", style: .default))
        present(ac, animated: true)
    }
    
    
    
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        case .notConnected:
            let ac = UIAlertController(title: "User has disconnected:", message: peerID.displayName, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            
            print("Not Connected: \(peerID.displayName)")
        @unknown default:
            print("Unknown state received: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        DispatchQueue.main.async { [weak self] in
            var strData = String(decoding: data, as: UTF8.self)
            if let image = UIImage(data: data) {
                self?.images.insert(image, at: 0)
                strData = ""
                self?.collectionView.reloadData()
            }
            
            if strData != "" {
                let ac = UIAlertController(title: "Message", message: strData, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(ac, animated: true)
            }
            
        }
    }
    
    
    
    // uygulamamızda işimize yaramayacak ama protokollerden dolayı çağırmamız gereken fonksiyonlar
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        //boş olacak
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        //boş olacak
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        //boş olacak
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        // iki yöntemin ikisi de çok eşli tarayıcı içindir: biri başarıyla tamamlandığında çağrılır, diğeri ise kullanıcı iptal ettiğinde.
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        // iki yöntemin ikisi de çok eşli tarayıcı içindir: biri başarıyla tamamlandığında çağrılır, diğeri ise kullanıcı iptal ettiğinde.
        dismiss(animated: true)
    }
    
    
    
    
    
    // resim seçme (picer) ayarları
    @objc func importPicture() {
        let picer = UIImagePickerController()
        picer.allowsEditing = true
        picer.delegate = self
        present(picer, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        dismiss(animated: true)
        
        images.insert(image, at: 0)
        collectionView.reloadData()
        
        //kullanıcıya paylaşmak için yazılan kod
        
        guard let mcSession = mcSession else { return }
        if mcSession.connectedPeers.count > 0 {
            if let imageData = image.pngData() {
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                }catch {
                    let ac = UIAlertController(title: "Send Error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
        
        
    }
    
    
    //collectionview ayarları
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageView", for: indexPath)
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
        }
        cell.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        cell.layer.borderWidth = 2
        cell.layer.cornerRadius = 7
        return cell
    }

}

