//
//  FavoriteService.swift
//  Gudi
//
//  Created by 林聖凱 on 2025/7/21.
//

import FirebaseFirestore
import FirebaseAuth

//管理 Firebase Firestore 中的我的最愛
class FavoriteService {
    private let db = Firestore.firestore()

    // 新增最愛股票代碼（如果文件不存在會自動建立）
    func addFavorite(stockCode: String, completion: ((Error?) -> Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "FavoriteService", code: 401, userInfo: [NSLocalizedDescriptionKey: "使用者未登入"]))
            return
        }
        
        let docRef = db.collection("favorites").document(uid)
        docRef.setData(["stockCodes": FieldValue.arrayUnion([stockCode])], merge: true) { error in
            completion?(error)
        }
    }

    // 移除最愛股票代碼
    func removeFavorite(stockCode: String, completion: ((Error?) -> Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "FavoriteService", code: 401, userInfo: [NSLocalizedDescriptionKey: "使用者未登入"]))
            return
        }

        let docRef = db.collection("favorites").document(uid)
        docRef.setData(["stockCodes": FieldValue.arrayRemove([stockCode])], merge: true) { error in
            completion?(error)
        }
    }

    // 取得使用者所有最愛股票代碼
    func getFavorites(completion: @escaping ([String]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        let docRef = db.collection("favorites").document(uid)
        docRef.getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let stockCodes = data["stockCodes"] as? [String] {
                completion(stockCodes)
            } else {
                completion([])
            }
        }
    }
}
