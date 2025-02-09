import CoreGraphics

import BasePublic
import BaseUIPublic
import LayoutKit
import NetworkingPublic

#if os(iOS)
import UIKit
#else
import AppKit
#endif

public struct DivBlockModelingContext {
  public let cardId: DivCardID
  private(set) var cardLogId: String?
  private(set) var parentDivStatePath: DivStatePath?
  let stateManager: DivStateManager
  public let blockStateStorage: DivBlockStateStorage
  let visibilityCounter: DivVisibilityCounting
  let lastVisibleBoundsCache: DivLastVisibleBoundsCache
  public let imageHolderFactory: DivImageHolderFactory
  let highPriorityImageHolderFactory: DivImageHolderFactory?
  let divCustomBlockFactory: DivCustomBlockFactory
  let fontProvider: DivFontProvider
  let flagsInfo: DivFlagsInfo
  let extensionHandlers: [String: DivExtensionHandler]
  let stateInterceptors: [String: DivStateInterceptor]
  let layoutDirection: UserInterfaceLayoutDirection
  let debugParams: DebugParams
  let scheduler: Scheduling
  let playerFactory: PlayerFactory?
  private(set) var childrenA11yDescription: String?
  private(set) weak var parentScrollView: ScrollView?
  public private(set) var errorsStorage: DivErrorsStorage
  private let persistentValuesStorage: DivPersistentValuesStorage
  let tooltipViewFactory: DivTooltipViewFactory?
  public let variablesStorage: DivVariablesStorage
  public private(set) var expressionResolver: ExpressionResolver
  private let variableValueProvider: (String) -> Any?
  private let functionsProvider: FunctionsProvider
  private let variableTracker: ExpressionResolver.VariableTracker
  public private(set) var parentPath: UIElementPath
  private(set) var sizeModifier: DivSizeModifier?

  public init(
    cardId: DivCardID,
    cardLogId: String? = nil,
    parentPath: UIElementPath? = nil,
    parentDivStatePath: DivStatePath? = nil,
    stateManager: DivStateManager,
    blockStateStorage: DivBlockStateStorage = DivBlockStateStorage(),
    visibilityCounter: DivVisibilityCounting? = nil,
    lastVisibleBoundsCache: DivLastVisibleBoundsCache? = nil,
    imageHolderFactory: DivImageHolderFactory,
    highPriorityImageHolderFactory: DivImageHolderFactory? = nil,
    divCustomBlockFactory: DivCustomBlockFactory? = nil,
    fontProvider: DivFontProvider? = nil,
    flagsInfo: DivFlagsInfo = .default,
    extensionHandlers: [DivExtensionHandler] = [],
    stateInterceptors: [DivStateInterceptor] = [],
    variablesStorage: DivVariablesStorage = DivVariablesStorage(),
    playerFactory: PlayerFactory? = nil,
    debugParams: DebugParams = DebugParams(),
    scheduler: Scheduling? = nil,
    childrenA11yDescription: String? = nil,
    parentScrollView: ScrollView? = nil,
    errorsStorage: DivErrorsStorage? = nil,
    layoutDirection: UserInterfaceLayoutDirection = .leftToRight,
    variableTracker: DivVariableTracker? = nil,
    persistentValuesStorage: DivPersistentValuesStorage? = nil,
    tooltipViewFactory: DivTooltipViewFactory? = nil
  ) {
    let variableTracker: ExpressionResolver.VariableTracker = { variables in
      variableTracker?.onVariablesUsed(cardId: cardId, variables: variables)
    }
    var extensionsHandlersDictionary = [String: DivExtensionHandler]()
    extensionHandlers.forEach {
      let id = $0.id
      if extensionsHandlersDictionary[id] != nil {
        DivKitLogger.failure("Duplicate DivExtensionHandler for: \(id)")
        return
      }
      extensionsHandlersDictionary[id] = $0
    }
    var stateInterceptorsDictionary = [String: DivStateInterceptor]()
    stateInterceptors.forEach {
      let id = $0.id
      if stateInterceptorsDictionary[id] != nil {
        DivKitLogger.failure("Duplicate DivStateInterceptor for: \(id)")
        return
      }
      stateInterceptorsDictionary[id] = $0
    }
    self.init(
      cardId: cardId,
      cardLogId: cardLogId,
      parentPath: parentPath,
      parentDivStatePath: parentDivStatePath,
      stateManager: stateManager,
      blockStateStorage: blockStateStorage,
      visibilityCounter: visibilityCounter,
      lastVisibleBoundsCache: lastVisibleBoundsCache,
      imageHolderFactory: imageHolderFactory,
      highPriorityImageHolderFactory: highPriorityImageHolderFactory,
      divCustomBlockFactory: divCustomBlockFactory,
      fontProvider: fontProvider,
      flagsInfo: flagsInfo,
      extensionHandlers: extensionsHandlersDictionary,
      stateInterceptors: stateInterceptorsDictionary,
      variablesStorage: variablesStorage,
      playerFactory: playerFactory,
      debugParams: debugParams,
      scheduler: scheduler,
      childrenA11yDescription: childrenA11yDescription,
      parentScrollView: parentScrollView,
      errorsStorage: errorsStorage,
      layoutDirection: layoutDirection,
      variableTracker: variableTracker,
      persistentValuesStorage: persistentValuesStorage,
      tooltipViewFactory: tooltipViewFactory
    )
  }

  init(
    cardId: DivCardID,
    cardLogId: String?,
    parentPath: UIElementPath?,
    parentDivStatePath: DivStatePath?,
    stateManager: DivStateManager,
    blockStateStorage: DivBlockStateStorage,
    visibilityCounter: DivVisibilityCounting?,
    lastVisibleBoundsCache: DivLastVisibleBoundsCache?,
    imageHolderFactory: DivImageHolderFactory,
    highPriorityImageHolderFactory: DivImageHolderFactory?,
    divCustomBlockFactory: DivCustomBlockFactory?,
    fontProvider: DivFontProvider?,
    flagsInfo: DivFlagsInfo,
    extensionHandlers: [String: DivExtensionHandler],
    stateInterceptors: [String: DivStateInterceptor],
    variablesStorage: DivVariablesStorage,
    playerFactory: PlayerFactory?,
    debugParams: DebugParams,
    scheduler: Scheduling?,
    childrenA11yDescription: String?,
    parentScrollView: ScrollView?,
    errorsStorage: DivErrorsStorage?,
    layoutDirection: UserInterfaceLayoutDirection,
    variableTracker: @escaping ExpressionResolver.VariableTracker,
    persistentValuesStorage: DivPersistentValuesStorage?,
    tooltipViewFactory: DivTooltipViewFactory?
  ) {
    self.cardId = cardId
    self.cardLogId = cardLogId
    let parentPath = parentPath ?? UIElementPath(cardId.rawValue)
    self.parentPath = parentPath
    self.parentDivStatePath = parentDivStatePath
    self.stateManager = stateManager
    self.blockStateStorage = blockStateStorage
    self.visibilityCounter = visibilityCounter ?? DivVisibilityCounter()
    self.lastVisibleBoundsCache = lastVisibleBoundsCache ?? DivLastVisibleBoundsCache()
    self.imageHolderFactory = imageHolderFactory
    self.highPriorityImageHolderFactory = highPriorityImageHolderFactory
    self.divCustomBlockFactory = divCustomBlockFactory ?? EmptyDivCustomBlockFactory()
    self.flagsInfo = flagsInfo
    self.fontProvider = fontProvider ?? DefaultFontProvider()
    self.playerFactory = playerFactory
    self.debugParams = debugParams
    self.scheduler = scheduler ?? TimerScheduler()
    self.childrenA11yDescription = childrenA11yDescription
    self.parentScrollView = parentScrollView
    self.errorsStorage = errorsStorage ?? DivErrorsStorage(errors: [])
    self.layoutDirection = layoutDirection
    self.variableTracker = variableTracker
    let persistentValuesStorage = persistentValuesStorage ?? DivPersistentValuesStorage()
    self.persistentValuesStorage = persistentValuesStorage
    self.tooltipViewFactory = tooltipViewFactory
    self.variablesStorage = variablesStorage
    self.extensionHandlers = extensionHandlers
    self.stateInterceptors = stateInterceptors

    let variableValueProvider: (String) -> Any? = {
      variablesStorage.getVariableValue(
        cardId: cardId,
        name: DivVariableName(rawValue: $0)
      )
    }
    self.variableValueProvider = variableValueProvider
    functionsProvider = FunctionsProvider(
      variableValueProvider: {
        variableTracker([DivVariableName(rawValue: $0)])
        return variableValueProvider($0)
      },
      persistentValuesStorage: persistentValuesStorage
    )
    self.expressionResolver = makeExpressionResolver(
      variableValueProvider: variableValueProvider,
      functionsProvider: functionsProvider,
      parentPath: parentPath,
      errorsStorage: errorsStorage,
      variableTracker: variableTracker
    )
  }

  public func getExtensionHandlers(for div: DivBase) -> [DivExtensionHandler] {
    guard let extensions = div.extensions else {
      return []
    }
    return extensions.compactMap {
      let id = $0.id
      if !extensionHandlers.keys.contains(id), !stateInterceptors.keys.contains(id) {
        addError(message: "No DivExtensionHandler for: \(id)")
      }
      return extensionHandlers[id]
    }
  }

  public func getStateInterceptor(for divState: DivState) -> DivStateInterceptor? {
    divState.extensions?.compactMap { stateInterceptors[$0.id] }.first
  }

  public func addError(message: String, causes: [DivError] = []) {
    errorsStorage.add(DivBlockModelingError(message, path: parentPath, causes: causes))
  }

  public func addWarning(message: String) {
    errorsStorage.add(DivBlockModelingWarning(message, path: parentPath))
  }

  func addError(error: Error) {
    if let divError = error as? DivError {
      errorsStorage.add(divError)
      return
    }
    errorsStorage.add(DivUnknownError(error, path: parentPath))
  }

  func makeBinding<T>(variableName: String, defaultValue: T) -> Binding<T> {
    let variableName = DivVariableName(rawValue: variableName)
    variableTracker([variableName])
    let value: T = variablesStorage
      .getVariableValue(cardId: cardId, name: variableName) ?? defaultValue
    let valueProp = Property<T>(
      getter: { value },
      setter: {
        guard let newValue = DivVariableValue($0) else { return }
        self.variablesStorage.update(
          cardId: cardId,
          name: variableName,
          value: newValue
        )
      }
    )
    return Binding(name: variableName.rawValue, value: valueProp)
  }
}

extension DivBlockModelingContext {
  func modifying(
    cardLogId: String? = nil,
    parentPath: UIElementPath? = nil,
    parentDivStatePath: DivStatePath? = nil,
    errorsStorage: DivErrorsStorage? = nil,
    sizeModifier: DivSizeModifier? = nil
  ) -> Self {
    let expressionResolver: ExpressionResolver
    let parentPath = parentPath ?? self.parentPath
    let errorsStorage = errorsStorage ?? self.errorsStorage
    if parentPath == self.parentPath {
      expressionResolver = self.expressionResolver
    } else {
      expressionResolver = makeExpressionResolver(
        variableValueProvider: variableValueProvider,
        functionsProvider: functionsProvider,
        parentPath: parentPath,
        errorsStorage: errorsStorage,
        variableTracker: variableTracker
      )
    }
    return modified(self) {
      $0.cardLogId = cardLogId ?? self.cardLogId
      $0.parentPath = parentPath
      $0.parentDivStatePath = parentDivStatePath ?? self.parentDivStatePath
      $0.errorsStorage = errorsStorage
      $0.sizeModifier = sizeModifier ?? self.sizeModifier
      $0.expressionResolver = expressionResolver
    }
  }

  func modifying(
    childrenA11yDescription: String?
  ) -> Self {
    modified(self) {
      $0.childrenA11yDescription = childrenA11yDescription
    }
  }
}

private func makeExpressionResolver(
  variableValueProvider: @escaping AnyCalcExpression.ValueProvider,
  functionsProvider: FunctionsProvider,
  parentPath: UIElementPath,
  errorsStorage: DivErrorsStorage?,
  variableTracker: @escaping ExpressionResolver.VariableTracker
) -> ExpressionResolver {
  ExpressionResolver(
    variableValueProvider: variableValueProvider,
    functionsProvider: functionsProvider,
    errorTracker: { [weak errorsStorage] error in
      errorsStorage?.add(DivExpressionError(error, path: parentPath))
    },
    variableTracker: variableTracker
  )
}
