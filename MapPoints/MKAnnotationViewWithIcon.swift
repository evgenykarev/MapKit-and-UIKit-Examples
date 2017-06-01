//
//  MKAnnotationViewWithOutsideGesture.swift
//  MapPoints
//
//  Created by Evgeny Karev on 31.05.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import MapKit

class MKAnnotationViewWithIcon: MKAnnotationView {
    private let deltaBetweenIcons: CGFloat = 3
    private var _iconView: UIImageView
    
    var iconSize: CGSize {
        guard let iconImage = _iconView.image else {
            return CGSize.zero
        }

        return iconImage.size
    }
    
    init(annotation: MKAnnotation?, reuseIdentifier: String?, icon: UIImage) {
        self._iconView = UIImageView(image: icon)
        self._iconView.layer.shadowOffset = CGSize(width: 0, height: 3)
        self._iconView.layer.shadowRadius = 3
        self._iconView.layer.shadowOpacity = 1
        self._iconView.isUserInteractionEnabled = true
        
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self._iconView = UIImageView(image: nil)
        
        super.init(coder: aDecoder)
    }
    
    var isIconShowed = false
    private var _imageBeforeIconShowed: UIImage?
    private var _imageWithTransparentAreaForIcon: UIImage?
    private var _centerOffsetBeforeIconShowed: CGPoint!
    private var _centerOffsetForImageWithTransparentAreaForIcon: CGPoint!

    private func calcImageAndOffsetForIconShow() {
        guard !isIconShowed else {
            return
        }
        
        // show cashed results
        if _imageBeforeIconShowed == image && _imageWithTransparentAreaForIcon != nil {
            return
        }

        _imageBeforeIconShowed = image
        _centerOffsetBeforeIconShowed = centerOffset
        
        let bufferViewWidth = max(image?.size.width ?? 0, iconSize.width)

        var bufferViewHeight = image?.size.height ?? 0
        bufferViewHeight += deltaBetweenIcons
        bufferViewHeight += iconSize.height

        let bufferView = UIView(frame: CGRect(x: 0, y: 0, width: bufferViewWidth, height: bufferViewHeight))
        bufferView.isOpaque = false
        bufferView.backgroundColor = UIColor.clear
        
        // draw current image
        if let currentImage = image {
            let currentImageSubview = UIImageView(image: currentImage)
            bufferView.addSubview(currentImageSubview)
            currentImageSubview.center.x = bufferView.center.x
            currentImageSubview.center.y += deltaBetweenIcons + iconSize.height
        }
        
        _centerOffsetForImageWithTransparentAreaForIcon = _centerOffsetBeforeIconShowed

        if let bufferViewImage = UIImage.image(from: bufferView) {
            _imageWithTransparentAreaForIcon = bufferViewImage
            _centerOffsetForImageWithTransparentAreaForIcon.y += -bufferViewImage.size.height/2 + (_imageBeforeIconShowed?.size.height ?? 0)/2
        } else {
            _imageWithTransparentAreaForIcon = image
        }
    }
    
    func showIcon() {
        guard !isIconShowed else {
            return
        }

        calcImageAndOffsetForIconShow()
        image = _imageWithTransparentAreaForIcon
        centerOffset = _centerOffsetForImageWithTransparentAreaForIcon
        
        self.addSubview(_iconView)
        _iconView.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        _iconView.center.y = _iconView.frame.height
        _iconView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

        UIView.animate(withDuration: 0.27, animations: {
            self._iconView.transform = CGAffineTransform.identity
        }, completion: { (_: Bool) in
            self.isIconShowed = true
        })
    }
    
    func hideIcon(completion: @escaping () -> Void) {
        guard isIconShowed else {
            return
        }

        UIView.animate(withDuration: 0.27, animations: {
            self._iconView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }, completion: { (_: Bool) in
            self._iconView.removeFromSuperview()
            self._iconView.transform = CGAffineTransform.identity
            
            // if image was not replaced, set previous image
            if self.image == self._imageWithTransparentAreaForIcon {
                self.image = self._imageBeforeIconShowed
                self.centerOffset = self._centerOffsetBeforeIconShowed
            }

            completion()
            
            self.isIconShowed = false
        })
    }

}

