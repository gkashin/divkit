// Generated code. Do not modify.

import CommonCorePublic
import Foundation
import Serialization

public final class NumberValueTemplate: TemplateValue {
  public static let type: String = "number"
  public let parent: String?
  public let value: Field<Expression<Double>>?

  public convenience init(dictionary: [String: Any], templateToType: [TemplateName: String]) throws {
    self.init(
      parent: dictionary["type"] as? String,
      value: dictionary.getOptionalExpressionField("value")
    )
  }

  init(
    parent: String?,
    value: Field<Expression<Double>>? = nil
  ) {
    self.parent = parent
    self.value = value
  }

  private static func resolveOnlyLinks(context: TemplatesContext, parent: NumberValueTemplate?) -> DeserializationResult<NumberValue> {
    let valueValue = parent?.value?.resolveValue(context: context) ?? .noValue
    var errors = mergeErrors(
      valueValue.errorsOrWarnings?.map { .nestedObjectError(field: "value", error: $0) }
    )
    if case .noValue = valueValue {
      errors.append(.requiredFieldIsMissing(field: "value"))
    }
    guard
      let valueNonNil = valueValue.value
    else {
      return .failure(NonEmptyArray(errors)!)
    }
    let result = NumberValue(
      value: valueNonNil
    )
    return errors.isEmpty ? .success(result) : .partialSuccess(result, warnings: NonEmptyArray(errors)!)
  }

  public static func resolveValue(context: TemplatesContext, parent: NumberValueTemplate?, useOnlyLinks: Bool) -> DeserializationResult<NumberValue> {
    if useOnlyLinks {
      return resolveOnlyLinks(context: context, parent: parent)
    }
    var valueValue: DeserializationResult<Expression<Double>> = parent?.value?.value() ?? .noValue
    context.templateData.forEach { key, __dictValue in
      switch key {
      case "value":
        valueValue = deserialize(__dictValue).merged(with: valueValue)
      case parent?.value?.link:
        valueValue = valueValue.merged(with: deserialize(__dictValue))
      default: break
      }
    }
    var errors = mergeErrors(
      valueValue.errorsOrWarnings?.map { .nestedObjectError(field: "value", error: $0) }
    )
    if case .noValue = valueValue {
      errors.append(.requiredFieldIsMissing(field: "value"))
    }
    guard
      let valueNonNil = valueValue.value
    else {
      return .failure(NonEmptyArray(errors)!)
    }
    let result = NumberValue(
      value: valueNonNil
    )
    return errors.isEmpty ? .success(result) : .partialSuccess(result, warnings: NonEmptyArray(errors)!)
  }

  private func mergedWithParent(templates: [TemplateName: Any]) throws -> NumberValueTemplate {
    guard let parent = parent, parent != Self.type else { return self }
    guard let parentTemplate = templates[parent] as? NumberValueTemplate else {
      throw DeserializationError.unknownType(type: parent)
    }
    let mergedParent = try parentTemplate.mergedWithParent(templates: templates)

    return NumberValueTemplate(
      parent: nil,
      value: value ?? mergedParent.value
    )
  }

  public func resolveParent(templates: [TemplateName: Any]) throws -> NumberValueTemplate {
    return try mergedWithParent(templates: templates)
  }
}
