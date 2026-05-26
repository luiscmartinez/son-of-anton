import AppKit
import SpriteKit

@MainActor
final class FloatingPetPanelController: FloatingPetPanelManaging {
	private let codexPet: MaliPet
	private let codogotchiPet: CodogotchiPet?
	private let demoFrameInterval: TimeInterval?
	private let visibleFrameProvider: () -> CGRect
	private var panel: NSPanel?
	private var scene: FloatingPetScene?
	private var currentState: ActivityState = .idle
	private var currentMode: VisualMode = .normal
	private var frameChangeHandler: ((CGRect) -> Void)?

	init(
		codexPet: MaliPet,
		codogotchiPet: CodogotchiPet?,
		demoFrameInterval: TimeInterval? = nil,
		visibleFrameProvider: @escaping () -> CGRect = {
			NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 800, height: 600)
		}
	) {
		self.codexPet = codexPet
		self.codogotchiPet = codogotchiPet
		self.demoFrameInterval = demoFrameInterval
		self.visibleFrameProvider = visibleFrameProvider
	}

	func show(frame: CGRect) {
		let panel = self.panel ?? makePanel(frame: frame)
		panel.setFrame(frame, display: true)

		if scene == nil {
			let scene = FloatingPetScene(
				size: frame.size,
				codexPet: codexPet,
				codogotchiPet: codogotchiPet,
				demoFrameInterval: demoFrameInterval
			)
			scene.update(state: currentState, visualMode: currentMode)
			self.scene = scene
			(panel.contentView as? FloatingPetInteractionView)?.presentScene(scene)
		} else {
			scene?.size = frame.size
			scene?.update(state: currentState, visualMode: currentMode)
		}

		panel.orderFrontRegardless()
		self.panel = panel
	}

	func hide() {
		panel?.orderOut(nil)
	}

	func apply(state: ActivityState, visualMode: VisualMode) {
		currentState = state
		currentMode = visualMode
		dbgLog(
			"DBG FloatingPetPanelController.apply: state=\(state.rawValue) visualMode=\(visualMode) scenePresent=\(scene != nil)"
		)
		scene?.update(state: state, visualMode: visualMode)
	}

	func setInteraction(_ interaction: FloatingInteraction?) {
		scene?.setInteraction(interaction)
	}

	func setFrameChangeHandler(_ handler: @escaping (CGRect) -> Void) {
		frameChangeHandler = handler
		(panel?.contentView as? FloatingPetInteractionView)?.frameChangeHandler = handler
	}

	private func makePanel(frame: CGRect) -> NSPanel {
		let panel = NSPanel(
			contentRect: frame,
			styleMask: [.borderless, .nonactivatingPanel],
			backing: .buffered,
			defer: false
		)
		panel.backgroundColor = .clear
		panel.isOpaque = false
		panel.hasShadow = false
		panel.level = .floating
		panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
		panel.hidesOnDeactivate = false
		panel.isReleasedWhenClosed = false
		panel.ignoresMouseEvents = false
		panel.contentView = makeContentView(frame: frame, panel: panel)
		return panel
	}

	private func makeContentView(frame: CGRect, panel: NSPanel) -> FloatingPetInteractionView {
		let view = FloatingPetInteractionView(
			frame: CGRect(origin: .zero, size: frame.size),
			visibleFrameProvider: { [weak panel, visibleFrameProvider] in
				panel?.screen?.visibleFrame ?? visibleFrameProvider()
			},
			interactionHandler: { [weak self] interaction in
				self?.scene?.setInteraction(interaction)
			}
		)
		view.frameChangeHandler = frameChangeHandler
		return view
	}
}

enum FloatingInteractionHitTarget: Equatable {
	case dragRegion
	case resizeAffordance
}

enum FloatingInteractionPolicy {
	static let resizeAffordanceSize = CGSize(width: 28, height: 28)

	static func hitTest(point: CGPoint, in bounds: CGRect) -> FloatingInteractionHitTarget {
		if resizeAffordanceRect(in: bounds).contains(point) {
			return .resizeAffordance
		}
		return .dragRegion
	}

	static func resizeAffordanceRect(in bounds: CGRect) -> CGRect {
		CGRect(
			x: bounds.maxX - resizeAffordanceSize.width,
			y: bounds.minY,
			width: resizeAffordanceSize.width,
			height: resizeAffordanceSize.height
		)
	}

	static func draggedFrame(
		from frame: CGRect,
		dragDelta: CGSize,
		visibleFrame: CGRect
	) -> CGRect {
		FloatingFramePolicy.clamp(
			CGRect(
				x: frame.origin.x + dragDelta.width,
				y: frame.origin.y + dragDelta.height,
				width: frame.width,
				height: frame.height
			),
			to: visibleFrame
		)
	}

	/// Maps raw pointer delta from a resize affordance drag into width/height
	/// growth. Horizontal-dominant drags scale uniformly from width so
	/// left-right motion resizes the pet; otherwise both axes apply (diagonal
	/// top-left→bottom-right resize from the bottom-right affordance).
	static func resizeDragDelta(from rawDelta: CGSize) -> CGSize {
		if abs(rawDelta.width) >= abs(rawDelta.height) {
			return CGSize(width: rawDelta.width, height: rawDelta.width)
		}
		return rawDelta
	}

	static func resizedFrame(
		from frame: CGRect,
		dragDelta: CGSize,
		visibleFrame: CGRect
	) -> CGRect {
		let scaledDelta = resizeDragDelta(from: dragDelta)
		return FloatingFramePolicy.clamp(
			CGRect(
				x: frame.origin.x,
				y: frame.origin.y,
				width: frame.width + scaledDelta.width,
				height: frame.height + scaledDelta.height
			),
			to: visibleFrame
		)
	}

	/// Whether the resize affordance icon should paint for the current pointer
	/// and interaction state.
	static func shouldShowResizeAffordance(
		pointerInAffordance: Bool,
		isResizing: Bool
	) -> Bool {
		pointerInAffordance || isResizing
	}

	/// Pure-function mapping from an in-flight pointer drag delta and the
	/// hit-tested target to the reserved-row interaction the floating scene
	/// should display. The resize affordance always picks `.jumping`; drags on
	/// the drag region pick `.runningRight` or `.runningLeft` when horizontal
	/// motion dominates vertical motion, and return `nil` otherwise so the
	/// ordinary activity-state animation remains visible during near-vertical
	/// drags.
	static func interaction(
		forDragDelta delta: CGSize,
		hitTarget: FloatingInteractionHitTarget
	) -> FloatingInteraction? {
		switch hitTarget {
		case .resizeAffordance:
			return .jumping
		case .dragRegion:
			let horizontalDominant = abs(delta.width) > abs(delta.height)
			guard horizontalDominant, delta.width != 0 else { return nil }
			return delta.width > 0 ? .runningRight : .runningLeft
		}
	}
}

private final class FloatingPetInteractionView: NSView {
	private enum ActiveInteraction {
		case drag(startFrame: CGRect, startScreenPoint: CGPoint)
		case resize(startFrame: CGRect, startScreenPoint: CGPoint)
	}

	private let skView = SKView(frame: .zero)
	private let resizeAffordanceView = FloatingResizeAffordanceView(frame: .zero)
	private let visibleFrameProvider: () -> CGRect
	private let interactionHandler: (FloatingInteraction?) -> Void
	private var activeInteraction: ActiveInteraction?
	private var lastEmittedInteraction: FloatingInteraction?
	private var affordanceHovered = false
	private var affordanceTrackingArea: NSTrackingArea?
	var frameChangeHandler: ((CGRect) -> Void)?

	init(
		frame: CGRect,
		visibleFrameProvider: @escaping () -> CGRect,
		interactionHandler: @escaping (FloatingInteraction?) -> Void
	) {
		self.visibleFrameProvider = visibleFrameProvider
		self.interactionHandler = interactionHandler
		super.init(frame: frame)

		wantsLayer = true
		layer?.backgroundColor = NSColor.clear.cgColor
		skView.allowsTransparency = true
		skView.ignoresSiblingOrder = true
		skView.autoresizingMask = [.width, .height]
		addSubview(skView)
		addSubview(resizeAffordanceView)
		resizeAffordanceView.isHidden = true
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		nil
	}

	func presentScene(_ scene: SKScene) {
		skView.presentScene(scene)
	}

	override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		window?.acceptsMouseMovedEvents = true
		updateTrackingAreas()
	}

	override func updateTrackingAreas() {
		super.updateTrackingAreas()
		if let affordanceTrackingArea {
			removeTrackingArea(affordanceTrackingArea)
		}
		let area = NSTrackingArea(
			rect: bounds,
			options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
			owner: self,
			userInfo: nil
		)
		addTrackingArea(area)
		affordanceTrackingArea = area
	}

	override var isFlipped: Bool { false }

	override func hitTest(_ point: NSPoint) -> NSView? {
		guard bounds.contains(point) else { return nil }
		return self
	}

	override func layout() {
		super.layout()
		skView.frame = bounds
		resizeAffordanceView.frame = FloatingInteractionPolicy.resizeAffordanceRect(in: bounds)
		updateTrackingAreas()
	}

	override func mouseMoved(with event: NSEvent) {
		let localPoint = convert(event.locationInWindow, from: nil)
		updateAffordanceHover(at: localPoint, reason: "mouseMoved")
	}

	override func mouseEntered(with event: NSEvent) {
		let localPoint = convert(event.locationInWindow, from: nil)
		updateAffordanceHover(at: localPoint, reason: "mouseEntered")
	}

	override func mouseExited(with event: NSEvent) {
		updateAffordanceHover(at: nil, reason: "mouseExited")
	}

	override func mouseDown(with event: NSEvent) {
		guard let window else { return }
		let localPoint = convert(event.locationInWindow, from: nil)
		let startScreenPoint = NSEvent.mouseLocation
		switch FloatingInteractionPolicy.hitTest(point: localPoint, in: bounds) {
		case .dragRegion:
			activeInteraction = .drag(startFrame: window.frame, startScreenPoint: startScreenPoint)
		case .resizeAffordance:
			activeInteraction = .resize(startFrame: window.frame, startScreenPoint: startScreenPoint)
			updateAffordanceHover(at: localPoint, reason: "mouseDown-resize")
		}
	}

	override func mouseDragged(with event: NSEvent) {
		guard let window, let activeInteraction else { return }
		let currentPoint = NSEvent.mouseLocation
		let nextFrame: CGRect
		let dragDelta: CGSize
		let hitTarget: FloatingInteractionHitTarget

		switch activeInteraction {
		case let .drag(startFrame, startScreenPoint):
			dragDelta = CGSize(
				width: currentPoint.x - startScreenPoint.x,
				height: currentPoint.y - startScreenPoint.y
			)
			hitTarget = .dragRegion
			nextFrame = FloatingInteractionPolicy.draggedFrame(
				from: startFrame,
				dragDelta: dragDelta,
				visibleFrame: visibleFrameProvider()
			)
		case let .resize(startFrame, startScreenPoint):
			let rawDelta = CGSize(
				width: currentPoint.x - startScreenPoint.x,
				height: currentPoint.y - startScreenPoint.y
			)
			dragDelta = FloatingInteractionPolicy.resizeDragDelta(from: rawDelta)
			hitTarget = .resizeAffordance
			nextFrame = FloatingInteractionPolicy.resizedFrame(
				from: startFrame,
				dragDelta: rawDelta,
				visibleFrame: visibleFrameProvider()
			)
			dbgLog(
				"DBG FloatingPetInteractionView resizeDrag: raw=\(rawDelta.width)x\(rawDelta.height) scaled=\(dragDelta.width)x\(dragDelta.height) frame=\(nextFrame.width)x\(nextFrame.height)"
			)
		}

		window.setFrame(nextFrame, display: true)

		let interaction = FloatingInteractionPolicy.interaction(
			forDragDelta: dragDelta,
			hitTarget: hitTarget
		)
		if interaction != lastEmittedInteraction {
			lastEmittedInteraction = interaction
			interactionHandler(interaction)
		}
	}

	override func mouseUp(with event: NSEvent) {
		let wasResizing = isResizing
		activeInteraction = nil
		if lastEmittedInteraction != nil {
			lastEmittedInteraction = nil
			interactionHandler(nil)
		}
		if let frame = window?.frame {
			frameChangeHandler?(frame)
		}
		let localPoint = convert(event.locationInWindow, from: nil)
		updateAffordanceHover(at: localPoint, reason: wasResizing ? "mouseUp-resize" : "mouseUp")
	}

	override func cursorUpdate(with event: NSEvent) {
		let localPoint = convert(event.locationInWindow, from: nil)
		if FloatingInteractionPolicy.resizeAffordanceRect(in: bounds).contains(localPoint) {
			FloatingResizeAffordanceView.resizeCursor.set()
		} else {
			NSCursor.arrow.set()
		}
	}

	private var isResizing: Bool {
		if case .resize = activeInteraction { return true }
		return false
	}

	private func updateAffordanceHover(at localPoint: CGPoint?, reason: String) {
		let pointerInAffordance: Bool
		if let localPoint {
			pointerInAffordance = FloatingInteractionPolicy.resizeAffordanceRect(in: bounds)
				.contains(localPoint)
		} else {
			pointerInAffordance = false
		}

		let shouldShow = FloatingInteractionPolicy.shouldShowResizeAffordance(
			pointerInAffordance: pointerInAffordance,
			isResizing: isResizing
		)
		let visibilityChanged = shouldShow != !resizeAffordanceView.isHidden
		affordanceHovered = pointerInAffordance
		resizeAffordanceView.isHidden = !shouldShow

		if visibilityChanged || pointerInAffordance {
			dbgLog(
				"DBG FloatingPetInteractionView affordance: reason=\(reason) hover=\(pointerInAffordance) resizing=\(isResizing) visible=\(shouldShow) point=\(localPoint.map { "\($0.x),\($0.y)" } ?? "nil") rect=\(FloatingInteractionPolicy.resizeAffordanceRect(in: bounds))"
			)
		}

		if shouldShow {
			FloatingResizeAffordanceView.resizeCursor.set()
		} else if !isResizing {
			NSCursor.arrow.set()
		}
	}
}

private final class FloatingResizeAffordanceView: NSView {
	static let resizeCursor: NSCursor = {
		if let image = NSImage(
			systemSymbolName: "arrow.up.left.and.arrow.down.right",
			accessibilityDescription: "Resize floating pet"
		) {
			let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
			let configured = image.withSymbolConfiguration(config) ?? image
			configured.size = NSSize(width: 14, height: 14)
			return NSCursor(image: configured, hotSpot: NSPoint(x: 7, y: 7))
		}
		return .crosshair
	}()

	override var isOpaque: Bool { false }

	override func draw(_ dirtyRect: NSRect) {
		let bgRect = bounds.insetBy(dx: 3, dy: 3)
		let background = NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.20, alpha: 0.94)
		let rounded = NSBezierPath(roundedRect: bgRect, xRadius: 5, yRadius: 5)
		background.setFill()
		rounded.fill()

		guard let symbol = NSImage(
			systemSymbolName: "arrow.up.left.and.arrow.down.right",
			accessibilityDescription: nil
		) else { return }

		let config = NSImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
			.applying(.init(hierarchicalColor: .white))
		let icon = symbol.withSymbolConfiguration(config) ?? symbol
		let iconSide = min(bgRect.width, bgRect.height) - 4
		icon.size = NSSize(width: iconSide, height: iconSide)
		let origin = NSPoint(
			x: bgRect.midX - iconSide / 2,
			y: bgRect.midY - iconSide / 2
		)
		icon.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
	}
}
