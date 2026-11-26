package vn.datahub.data.shared.security;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.web.authentication.BearerTokenAuthenticationFilter;
import org.springframework.security.web.SecurityFilterChain;
import vn.datahub.data.shared.web.ProblemWriter;

/**
 * Máy chủ tài nguyên JWT RS256, phi trạng thái, mặc định từ chối (CC-SEC-08). Quyền đọc từ claim
 * {@code perms} (PERM-*) và {@code roles} (ROLE-* hoặc tên trần) theo SS-07-09.
 */
@Configuration(proxyBeanMethods = false)
@EnableMethodSecurity
class SecurityConfig {

  @Bean
  SecurityFilterChain apiChain(HttpSecurity http, ProblemWriter problems) throws Exception {
    return http.csrf(AbstractHttpConfigurer::disable)
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(
            a ->
                a.requestMatchers(HttpMethod.OPTIONS, "/**")
                    .permitAll()
                    .anyRequest()
                    .authenticated())
        .oauth2ResourceServer(
            o ->
                o.jwt(j -> j.jwtAuthenticationConverter(jwtAuthenticationConverter()))
                    .authenticationEntryPoint(new ProblemAuthenticationEntryPoint(problems)))
        .exceptionHandling(
            e ->
                e.authenticationEntryPoint(new ProblemAuthenticationEntryPoint(problems))
                    .accessDeniedHandler(new ProblemAccessDeniedHandler(problems)))
        .addFilterAfter(new TenantContextFilter(), BearerTokenAuthenticationFilter.class)
        .build();
  }

  @Bean
  JwtDecoder jwtDecoder(JwtProperties props) {
    NimbusJwtDecoder decoder = NimbusJwtDecoder.withPublicKey(JwtKeys.load(props)).build();
    List<OAuth2TokenValidator<Jwt>> validators = new ArrayList<>();
    validators.add(
        props.issuer() == null || props.issuer().isBlank()
            ? JwtValidators.createDefault()
            : JwtValidators.createDefaultWithIssuer(props.issuer()));
    validators.add(claimsValidator());
    decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(validators));
    return decoder;
  }

  /** {@code sub} phải là UUID và {@code tenant} là Tnn hoặc PLATFORM (SS-07-09, SS-07-12). */
  static OAuth2TokenValidator<Jwt> claimsValidator() {
    return jwt -> {
      boolean ok = TenantContext.isValidTokenTenant(jwt.getClaimAsString("tenant"));
      try {
        UUID.fromString(String.valueOf(jwt.getSubject()));
      } catch (IllegalArgumentException e) {
        ok = false;
      }
      return ok
          ? OAuth2TokenValidatorResult.success()
          : OAuth2TokenValidatorResult.failure(
              new OAuth2Error("invalid_token", "Claim sub hoặc tenant không hợp lệ", null));
    };
  }

  static JwtAuthenticationConverter jwtAuthenticationConverter() {
    JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
    converter.setJwtGrantedAuthoritiesConverter(SecurityConfig::authorities);
    return converter;
  }

  static List<GrantedAuthority> authorities(Jwt jwt) {
    List<GrantedAuthority> result = new ArrayList<>();
    for (String perm : CurrentUserProvider.claimSet(jwt, "perms")) {
      result.add(new SimpleGrantedAuthority(perm));
    }
    for (String role : CurrentUserProvider.claimSet(jwt, "roles")) {
      String name = role.startsWith("ROLE-") ? role.substring("ROLE-".length()) : role;
      result.add(new SimpleGrantedAuthority("ROLE_" + name));
    }
    return result;
  }
}
