package com.kyumin.ledger.controller;

import org.springframework.boot.webmvc.error.ErrorController;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;
import jakarta.servlet.http.HttpServletRequest;

@Controller
public class CustomErrorController implements ErrorController {

    @RequestMapping("/error")
    public ModelAndView handleError(HttpServletRequest request) {
        Object statusCode = request.getAttribute("jakarta.servlet.error.status_code");

        if (statusCode != null) {
            int code = Integer.parseInt(statusCode.toString());
            if (code == HttpStatus.NOT_FOUND.value()) {
                return new ModelAndView("forward:/error/404.html");
            } else if (code == HttpStatus.INTERNAL_SERVER_ERROR.value()) {
                return new ModelAndView("forward:/error/500.html");
            }
        }

        return new ModelAndView("forward:/error/404.html");
    }
}