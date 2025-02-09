// Generated code. Do not modify.

package com.yandex.div2

import android.graphics.Color
import android.net.Uri
import androidx.annotation.ColorInt
import com.yandex.div.json.*
import com.yandex.div.json.expressions.Expression
import com.yandex.div.json.expressions.ExpressionsList
import com.yandex.div.json.schema.*
import com.yandex.div.core.annotations.Mockable
import java.io.IOException
import java.util.BitSet
import org.json.JSONObject
import com.yandex.div.data.*
import org.json.JSONArray

@Mockable
sealed class EnumWithDefaultType : JSONSerializable {
    class WithDefaultCase(val value: WithDefault) : EnumWithDefaultType()
    class WithoutDefaultCase(val value: WithoutDefault) : EnumWithDefaultType()

    fun value(): Any {
        return when (this) {
            is WithDefaultCase -> value
            is WithoutDefaultCase -> value
        }
    }

    override fun writeToJSON(): JSONObject {
        return when (this) {
            is WithDefaultCase -> value.writeToJSON()
            is WithoutDefaultCase -> value.writeToJSON()
        }
    }

    companion object {
        @Throws(ParsingException::class)
        @JvmStatic
        @JvmName("fromJson")
        operator fun invoke(env: ParsingEnvironment, json: JSONObject): EnumWithDefaultType {
            val logger = env.logger
            val type: String = json.readOptional("type", logger = logger, env = env) ?: WithDefault.TYPE
            when (type) {
                WithDefault.TYPE -> return WithDefaultCase(WithDefault(env, json))
                WithoutDefault.TYPE -> return WithoutDefaultCase(WithoutDefault(env, json))
            }
            val template = env.templates.getOrThrow(type, json) as? EnumWithDefaultTypeTemplate
            if (template != null) {
                return template.resolve(env, json)
            } else {
                throw typeMismatch(json = json, key = "type", value = type)
            }
        }
        val CREATOR = { env: ParsingEnvironment, it: JSONObject -> EnumWithDefaultType(env, json = it) }
    }
}
