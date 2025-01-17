//
//  DetailViewController.swift
//  Diary
//
//  Copyright (c) 2022 woong, jeremy All rights reserved.
//

import UIKit


final class DetailViewController: UIViewController {
    @IBOutlet private weak var detailTextViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var detailTextView: UITextView!
    private var coreDataManager: CoreDataManager = CoreDataManager()
    var diaryData: DiaryData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        addNotificationObserver()
        setAddButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeNotificationObserver()
        setDiaryDataFromTextView()
        coreDataManager.update()
    }
    
    private func setAddButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "더보기",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(moreButtonAlert))
    }
    
    private func configureView() {
        guard let diaryData = diaryData else { return }
        navigationItem.title = diaryData.createdAt?.convertDate()
        detailTextView.delegate = self
        guard let title = diaryData.title, !title.isEmpty,
              let body = diaryData.body else {
            detailTextView.text = "제목과 내용을 입력해주세요!"
            detailTextView.textColor = .gray
            return
        }
        detailTextView.text = "\(title)\n\n\(body)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func setDiaryDataFromTextView() {
        if detailTextView.text.contains("제목과 내용을 입력해주세요!") {
            detailTextView.text = ""
        }
        let result = detailTextView.text.separateTitleAndBody(titleWordsLimit: 20)
        diaryData?.body = result.body
        diaryData?.title = result.title
    }
    
    func setDiaryData(diaryData: DiaryData) {
        self.diaryData = diaryData
    }
    
}

// MARK: - Notification: handled keyboard Method

extension DetailViewController {
    private func addNotificationObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_ :)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_ :)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneWillDeactivate),
                                               name: UIScene.willDeactivateNotification,
                                               object: nil)
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillShowNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillHideNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIScene.willDeactivateNotification,
                                                  object: nil)
    }
    
    @objc
    private func keyboardWillShow(_ notification: Notification) {
        handleScrollView(notification, isAppearing: true)
    }
    
    @objc
    private func keyboardWillHide(_ notification: Notification) {
        handleScrollView(notification, isAppearing: false)
        setDiaryDataFromTextView()
        coreDataManager.update()
    }
    
    @objc
    private func sceneWillDeactivate() {
        setDiaryDataFromTextView()
        coreDataManager.update()
    }
    
    private func handleScrollView(_ notification: Notification, isAppearing: Bool) {
        guard let userinfo = notification.userInfo,
              let keyboardFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else {
            return
        }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        detailTextViewBottomConstraint.constant = isAppearing ? keyboardHeight : .zero
    }
}

// MARK: - extnesion: seperate detailTextView Title & Body

fileprivate extension String {
    func separateTitleAndBody(titleWordsLimit: Int) -> SeparatedText {
        let data = self.trimmingCharacters(in: .whitespacesAndNewlines)
        var components = data.components(separatedBy: "\n\n")
        if components[0].isEmpty {
            return SeparatedText()
        }
        if components.count > 1 {
            let title = components.removeFirst()
            let body = components.filter { $0 != ""}.joined(separator: "\n\n")
            return SeparatedText(title: title,
                                 body: body)
        }
        let limitIndex = data.index(startIndex, offsetBy: titleWordsLimit)
        let title = self[data.startIndex..<limitIndex]
        let body = self[limitIndex..<data.endIndex]
        return SeparatedText(title: title.description,
                             body: body.description)
    }
}

// MARK: - extension: Delete & Share Alert

extension DetailViewController {
    
    @objc
    private func moreButtonAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let shareAction = UIAlertAction(title: "Share..", style: .default) { action in
            self.presentActivityController()
        }
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { action in
            self.deleteAlert()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(shareAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    private func presentActivityController() {
        guard let title = diaryData?.title else { return }
        let textToShare: String = title
        let activityController = UIActivityViewController(activityItems: [textToShare],
                                                          applicationActivities: nil)
        activityController.excludedActivityTypes = [.addToReadingList]
        self.present(activityController, animated: true)
    }
    
    private func deleteAlert() {
        let alert = UIAlertController(title: "진짜요?", message: "정말로 삭제하시겠어요?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "삭제", style: .destructive) { action in
            guard let diaryData = self.diaryData else { return }
            self.coreDataManager.delete(data: diaryData)
            self.navigationController?.popViewController(animated: true)
        }
        let noAction = UIAlertAction(title: "취소", style: .default)
        alert.addAction(okAction)
        alert.addAction(noAction)
        present(alert, animated: true)
    }
}

// MARK: - extension: TextViewDelegate

extension DetailViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if detailTextView.text == "제목과 내용을 입력해주세요!" {
            detailTextView.text = ""
            detailTextView.textColor = .black
        }
    }
}
