//
//  CycleScrollView.swift
//  CycleScrollView
//
//  Created by wood on 2020/3/26.
//  Copyright © 2020 wood. All rights reserved.
//

import UIKit
import Kingfisher

/// PageControlStyle
///
/// - none: 隐藏PageControl
/// - system: 系统样式
@objc public enum PageControlStyle: Int {
    /// 隐藏
    case none
    /// 系统样式
    case system
}

/// PageControlPosition
///
/// - center: pageControl居中
/// - left: pageControl居左
/// - right: pageControl居右
@objc public enum PageControlPosition: Int {
    /// pageControl居中
    case center
    /// pageControl居左
    case left
    /// pageControl居右
    case right
}


/// CycleScrollViewDelegate
@objc public protocol CycleScrollViewDelegate: NSObjectProtocol {
    
    /// 点击轮播图的某一张图片回调事件
    /// - Parameters:
    ///   - cycleScrollView: 轮播图控件对象
    ///   - index: 点击所在下标
    @objc func cycleScrollView(_ cycleScrollView: CycleScrollView, didSelectItem index: Int)
    
    /// 滚动到某一张图标时回调，可以用来确定滚动到了哪个位置更新下标用
    /// - Parameters:
    ///   - cycleScrollView: 轮播图控件对象
    ///   - index: 滚动结束时所在下标
    @objc optional func cycleScrollView(_ cycleScrollView: CycleScrollView, didScrollTo index: Int)
}

/// DidSelectItemAtIndexBlock
public typealias DidSelectItemAtIndexBlock = (Int) -> Void


/// 无限轮播图（支持Swift和Objective-C）
open class CycleScrollView: UIView {
    
    /// ScrollDirection
    ///
    /// - horizontal: 水平（横向滚动），默认值
    /// - vertical: 垂直（上下滚动）
    @objc public enum ScrollDirection: Int {
        /// 水平（横向滚动）
        case horizontal
        /// 垂直（上下滚动）
        case vertical
    }
    
    // MAKR: DataSource
    /// Image Paths
    @objc open var imagePaths: [String] = [] {
        didSet {
            totalItemsCount = infiniteLoop ? imagePaths.count * 100 : imagePaths.count
            if imagePaths.count > 1 {
                collectionView.isScrollEnabled = true
                if autoScroll {
                    setupTimer()
                }
            } else {
                collectionView.isScrollEnabled = false
                invalidateTimer()
            }
            
            collectionView.reloadData()
            
            setupPageControl()
        }
    }
    
    /// Titles
    @objc open var titles: [String] = [] {
        didSet {
            if titles.count > 0 {
                if imagePaths.count == 0 {
                    imagePaths = titles
                }
            }
        }
    }
    
    // MARK:- Closure
    /// 点击图片回调所在index
    @objc open var didSelectItemBlock: DidSelectItemAtIndexBlock? = nil
    
    /// 滚动回调所在index
    @objc open var didScrollItemBlock: DidSelectItemAtIndexBlock? = nil
    
    /// 协议
    open weak var delegate: CycleScrollViewDelegate?
    
    // MARK:- Config
    /// 自动轮播- 默认true
    @objc open var autoScroll: Bool = true {
        didSet {
            invalidateTimer()
            // 如果关闭的无限循环，则不进行计时器的操作，否则每次滚动到最后一张就不在进行了。
            if autoScroll && infiniteLoop {
                setupTimer()
            }
        }
    }
    
    /// 无限循环- 默认true，此属性修改了就不存在轮播的意义了
    @objc open var infiniteLoop: Bool = true {
        didSet {
            if imagePaths.count > 0 {
                let temp = imagePaths
                imagePaths = temp
            }
        }
    }
    
    /// 滚动方向，默认horizontal
    open var scrollDirection: ScrollDirection = .horizontal {
        didSet {
            if scrollDirection == .horizontal {
                flowLayout?.scrollDirection = .horizontal
                position = .centeredHorizontally
            } else {
                flowLayout?.scrollDirection = .vertical
                position = .centeredVertically
            }
        }
    }
    
    /// 滚动间隔时间,默认2秒
    @objc open var autoScrollTimeInterval: Double = 2.0 {
        didSet {
            autoScroll = true
        }
    }
    
    
    // MARK:- Style
    /// Background Color
    @objc open var collectionViewBackgroundColor: UIColor! = UIColor.clear
    
    /// Load Placeholder Image
    @objc open var placeHolderImage: UIImage? = UIImage(named: "CycleScrollView.bundle/placeholder.png", in: Bundle(for: CycleScrollView.self), compatibleWith: nil)
    
    /// No Data Placeholder Image
    @objc open var coverImage: UIImage? = UIImage(named: "CycleScrollView.bundle/placeholder.png", in: Bundle(for: CycleScrollView.self), compatibleWith: nil)
    
    // MARK: ImageView
    /// Content Mode
    open var imageViewContentMode: UIView.ContentMode? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    // MARK: Title
    /// Color
    @objc open var textColor: UIColor = UIColor.white
    
    /// Number Lines
    @objc open var numberOfLines: Int = 2
    
    /// Title Leading
    @objc open var titleLeading: CGFloat = 15
    
    /// Font
    @objc open var font: UIFont = UIFont.systemFont(ofSize: 15)
    
    /// Background
    @objc open var titleBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3)
    
    // MARK: PageControl
    /// 注意： 由于属性较多，所以请使用style对应的属性，如果没有标明则通用
    /// PageControl
    @objc open var pageControl: UIPageControl?
    
    /// PageControlStyle
    @objc open var pageControlStyle: PageControlStyle = .system
    
    /// Tint Color
    @objc open var pageControlTintColor: UIColor = UIColor.lightGray
    
    // InActive Color
    @objc open var pageControlCurrentPageColor: UIColor = UIColor.white
    
    /// Position
    @objc open var pageControlPosition: PageControlPosition = .center
    
    /// Leading
    @objc open var pageControlLeadingOrTrialingContact: CGFloat = 28
    
    /// Bottom
    @objc open var pageControlBottom: CGFloat = 18
    
    /// 开启/关闭URL特殊字符处理
    @objc open var isAddingPercentEncodingForURLString: Bool = false
    
    
    // MARK:- Private
    /// 总数量
    fileprivate var totalItemsCount: Int! = 1
    
    /// 最大伸展空间(防止出现问题，可外部设置)
    /// 用于反方向滑动的时候，需要知道最大的contentSize
    fileprivate var maxSwipeSize: CGFloat = 0
    
    /// 是否纯文本
    fileprivate var isOnlyTitle: Bool = false
    
    /// 高度
    fileprivate var cellHeight: CGFloat = 56
    
    /// Collection滚动方向
    fileprivate var position: UICollectionView.ScrollPosition! = .centeredHorizontally
    
    /// 计时器
    fileprivate var dtimer: DispatchSourceTimer?
    
    /// 容器组件 UICollectionView
    fileprivate var collectionView: UICollectionView!
    
    // Identifier
    fileprivate let identifier = "CycleScrollViewCell"
    
    /// UICollectionViewFlowLayout
    lazy fileprivate var flowLayout: UICollectionViewFlowLayout? = {
        let tempFlowLayout = UICollectionViewFlowLayout()
        tempFlowLayout.minimumLineSpacing = 0
        tempFlowLayout.scrollDirection = .horizontal
        return tempFlowLayout
    }()
    
    
    /// Init
    ///
    /// - Parameter frame: CGRect
    override internal init(frame: CGRect) {
        super.init(frame: frame)
        setupMainView()
    }
    
    /// Init
    ///
    /// - Parameter aDecoder: NSCoder
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupMainView()
    }
}

// MARK: 类初始化
extension CycleScrollView {
    /// 默认初始化
    ///
    /// - Parameters:
    ///   - frame: Frame
    ///   - imageURLPaths: URL Path Array
    ///   - titles: Title Array
    ///   - didSelectItemBlock: DidSelectItemAtIndexBlock
    /// - Returns: CycleScrollView
    @objc open class func cycleScrollViewWithFrame(_ frame: CGRect, imageURLPaths: [String]? = [], titles:[String]? = [], didSelectItemBlock: DidSelectItemAtIndexBlock? = nil) -> CycleScrollView {
        let cycleScrollView: CycleScrollView = CycleScrollView(frame: frame)
        // Nil
        cycleScrollView.imagePaths = []
        cycleScrollView.titles = []
        
        if let imageURLPathList = imageURLPaths, imageURLPathList.count > 0 {
            cycleScrollView.imagePaths = imageURLPathList
        }
        
        if let titleList = titles, titleList.count > 0 {
            cycleScrollView.titles = titleList
        }
        
        if didSelectItemBlock != nil {
            cycleScrollView.didSelectItemBlock = didSelectItemBlock
        }
        return cycleScrollView
    }
    
    /// 纯文本
    ///
    /// - Parameters:
    ///   - frame: Frame
    ///   - backImage: Background Image
    ///   - titles: Title Array
    ///   - didSelectItemBlock: DidSelectItemAtIndexBlock
    /// - Returns: CycleScrollView
    @objc open class func cycleScrollViewWithTitles(frame: CGRect, backImage: UIImage? = nil, titles: [String]? = [], didSelectItemBlock: DidSelectItemAtIndexBlock? = nil) -> CycleScrollView {
        let cycleScrollView: CycleScrollView = CycleScrollView(frame: frame)
        // Nil
        cycleScrollView.titles = []
        
        if let backImage = backImage {
            // 异步加载数据时候，第一个页面会出现placeholder image，可以用backImage来设置纯色图片等其他方式
            cycleScrollView.coverImage = backImage
        }
        
        // Set isOnlyTitle
        cycleScrollView.isOnlyTitle = true
        
        // Titles Data
        if let titleList = titles, titleList.count > 0 {
            cycleScrollView.titles = titleList
        }
        
        if didSelectItemBlock != nil {
            cycleScrollView.didSelectItemBlock = didSelectItemBlock
        }
        return cycleScrollView
    }
    
}

// MARK: UI
extension CycleScrollView {
    // MARK: 添加UICollectionView
    private func setupMainView() {
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout!)
        collectionView.register(CycleScrollViewCell.self, forCellWithReuseIdentifier: identifier)
        collectionView.backgroundColor = collectionViewBackgroundColor
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.scrollsToTop = false
        self.addSubview(collectionView)
        setupPageControl()
    }
    

    // MARK: 添加PageControl
    func setupPageControl() {
        
        if pageControlStyle == .system {
            if pageControl == nil {
                pageControl = UIPageControl()
                self.addSubview(pageControl!)
            }
            pageControl?.pageIndicatorTintColor = pageControlTintColor
            pageControl?.currentPageIndicatorTintColor = pageControlCurrentPageColor
            pageControl?.numberOfPages = self.imagePaths.count
            pageControl?.isHidden = false
        }
        
        if imagePaths.count <= 1 {
            pageControl?.isHidden = true
            return
        }
        
        if pageControlStyle == .none {
            pageControl?.isHidden = true
        }
        
        calcScrollViewToScroll(collectionView)
    }
}

// MARK: UIViewHierarchy | LayoutSubviews
extension CycleScrollView {
    /// 将要添加到 window 上时
    ///
    /// - Parameter newWindow: 新的 window
    /// 添加到window 上时 开启 timer, 从 window 上移除时, 移除 timer
    override open func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow != nil {
            if autoScroll && infiniteLoop {
                setupTimer()
            }
        } else {
            invalidateTimer()
        }
    }
    
    // MARK: layoutSubviews
    override open func layoutSubviews() {
        super.layoutSubviews()
        // CollectionView
        collectionView.frame = self.bounds
        
        // Cell Height
        cellHeight = collectionView.frame.height
        
        // 计算最大扩展区大小
        if scrollDirection == .horizontal {
            maxSwipeSize = CGFloat(imagePaths.count) * collectionView.frame.width
        } else {
            maxSwipeSize = CGFloat(imagePaths.count) * collectionView.frame.height
        }
        
        // Cell Size
        flowLayout?.itemSize = self.frame.size
        
        // pageControl width
        let pageControlWidth = self.bounds.width
        
        // Page Frame
        if pageControlStyle == .system {
            if pageControlPosition == .center {
                pageControl?.frame = CGRect(x: 0, y: self.cycle_height-pageControlBottom, width: pageControlWidth, height: 10)
            } else {
                let pointSize = pageControl?.size(forNumberOfPages: self.imagePaths.count)
                if pageControlPosition == .left {
                    pageControl?.frame = CGRect(x: -(pageControlWidth - (pointSize?.width)! - pageControlLeadingOrTrialingContact) * 0.5, y: self.cycle_height-pageControlBottom, width: pageControlWidth, height: 10)
                } else {
                    pageControl?.frame = CGRect(x: (pageControlWidth - (pointSize?.width)! - pageControlLeadingOrTrialingContact) * 0.5, y: self.cycle_height-pageControlBottom, width: pageControlWidth, height: 10)
                }
            }
        }
        
        if collectionView.contentOffset.x == 0 && totalItemsCount > 0 {
            var targetIndex = 0
            if infiniteLoop {
                targetIndex = totalItemsCount/2
            }
            collectionView.scrollToItem(at: IndexPath(item: targetIndex, section: 0), at: position, animated: false)
        }
    }
}

// MARK: 定时器模块
extension CycleScrollView {
    /// 添加DTimer
    func setupTimer() {
        // 仅一张图不进行滚动操纵
        if self.imagePaths.count <= 1 { return }
        
        invalidateTimer()
        
        let l_dtimer = DispatchSource.makeTimerSource()
        l_dtimer.schedule(deadline: .now()+autoScrollTimeInterval, repeating: autoScrollTimeInterval)
        l_dtimer.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.automaticScroll()
            }
        }
        // 继续
        l_dtimer.resume()
        
        dtimer = l_dtimer
    }
    
    /// 关闭倒计时
    func invalidateTimer() {
        dtimer?.cancel()
        dtimer = nil
    }
}

// MARK: Events
extension CycleScrollView {
    /// 自动轮播
    @objc func automaticScroll() {
        if totalItemsCount == 0 {return}
        let targetIndex = currentIndex() + 1
        scrollToIndex(targetIndex: targetIndex)
    }
    
    /// 滚动到指定位置
    ///
    /// - Parameter targetIndex: 下标-Index
    @objc open func scrollToIndex(targetIndex: Int) {
        if targetIndex >= totalItemsCount {
            if infiniteLoop {
                collectionView.scrollToItem(at: IndexPath(item: Int(totalItemsCount/2), section: 0), at: position, animated: false)
            }
            return
        }
        collectionView.scrollToItem(at: IndexPath(item: targetIndex, section: 0), at: position, animated: true)
    }
    
    /// 当前位置
    ///
    /// - Returns: 下标-Index
    @objc open func currentIndex() -> Int {
        if collectionView.cycle_width == 0 || collectionView.cycle_height == 0 {
            return 0
        }
        var index = 0
        if flowLayout?.scrollDirection == UICollectionView.ScrollDirection.horizontal {
            index = Int(collectionView.contentOffset.x + (flowLayout?.itemSize.width)! * 0.5)/Int((flowLayout?.itemSize.width)!)
        } else {
            index = Int(collectionView.contentOffset.y + (flowLayout?.itemSize.height)! * 0.5)/Int((flowLayout?.itemSize.height)!)
        }
        return index
    }
    
    /// PageControl当前下标对应的Cell位置
    ///
    /// - Parameter index: PageControl Index
    /// - Returns: Cell Index
    func pageControlIndexWithCurrentCellIndex(index: Int) -> (Int) {
        return imagePaths.count == 0 ? 0 : Int(index % imagePaths.count)
    }
    
    /// 滚动上一个/下一个
    ///
    /// - Parameter gesture: 手势
    @objc open func scrollByDirection(_ gestureRecognizer: UITapGestureRecognizer) {
        if let index = gestureRecognizer.view?.tag {
            if autoScroll {
                invalidateTimer()
            }
            
            scrollToIndex(targetIndex: currentIndex() + (index == 0 ? -1 : 1))
        }
    }
}

// MARK: UICollectionViewDelegate, UICollectionViewDataSource
extension CycleScrollView: UICollectionViewDelegate, UICollectionViewDataSource {
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemsCount == 0 ? 1:totalItemsCount
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: CycleScrollViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CycleScrollViewCell
        // Setting
        cell.titleFont = font
        cell.titleLabelTextColor = textColor
        cell.titleBackViewBackgroundColor = titleBackgroundColor
        cell.titleLines = numberOfLines
        
        // Leading
        cell.titleLabelLeading = titleLeading
        
        // Only Title
        if isOnlyTitle && titles.count > 0 {
            cell.titleLabelHeight = cellHeight
            
            let itemIndex = pageControlIndexWithCurrentCellIndex(index: indexPath.item)
            cell.title = titles[itemIndex]
        } else {
            // Mode
            if let imageViewContentMode = imageViewContentMode {
                cell.imageView.contentMode = imageViewContentMode
            }
            
            // 0==count 占位图
            if imagePaths.count == 0 {
                cell.imageView.image = coverImage
            } else {
                let itemIndex = pageControlIndexWithCurrentCellIndex(index: indexPath.item)
                let imagePath = imagePaths[itemIndex]
                
                // 根据imagePath，来判断是网络图片还是本地图
                if imagePath.hasPrefix("http") {
                    let escapedString = imagePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                    cell.imageView.kf.setImage(with: URL(string: isAddingPercentEncodingForURLString ? escapedString ?? imagePath : imagePath), placeholder: placeHolderImage)
                } else {
                    if let image = UIImage(named: imagePath) {
                        cell.imageView.image = image;
                    } else {
                        cell.imageView.image = UIImage(contentsOfFile: imagePath)
                    }
                }
                
                // 对冲数据判断
                if itemIndex <= titles.count-1 {
                    cell.title = titles[itemIndex]
                } else {
                    cell.title = ""
                }
            }
        }
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = pageControlIndexWithCurrentCellIndex(index: indexPath.item)
        didSelectItemBlock?(index)
        delegate?.cycleScrollView(self, didSelectItem: index)
    }
}

// MARK: UIScrollViewDelegate
extension CycleScrollView: UIScrollViewDelegate {
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if imagePaths.count == 0 { return }
        calcScrollViewToScroll(scrollView)
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if autoScroll {
            invalidateTimer()
        }
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if imagePaths.count == 0 { return }
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: currentIndex())
        
        // 滚动后的回调协议
        delegate?.cycleScrollView?(self, didScrollTo: indexOnPageControl)
        didScrollItemBlock?(indexOnPageControl)
        
        if autoScroll {
            setupTimer()
        }
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if imagePaths.count == 0 { return }
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: currentIndex())
        
        // 滚动后的回调协议
        delegate?.cycleScrollView?(self, didScrollTo: indexOnPageControl)
        didScrollItemBlock?(indexOnPageControl)
        
        if dtimer == nil && autoScroll {
            setupTimer()
        }
    }
    
    fileprivate func calcScrollViewToScroll(_ scrollView: UIScrollView) {
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: currentIndex())
        if pageControlStyle == .system {
            pageControl?.currentPage = indexOnPageControl
        }
    }
}


